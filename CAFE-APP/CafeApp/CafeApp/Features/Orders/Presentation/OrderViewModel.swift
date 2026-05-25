import Foundation
import Observation

@Observable
final class OrderViewModel {
    var cart: [OrderItem] = []
    var activeOrder: Order?
    var isLoading = false
    var errorMessage: String?
    var cafeConfig: CafeConfig?

    private let placeOrderUseCase: PlaceOrderUseCase
    private let orderRepository: any OrderRepository
    private let cafeConfigRepository: any CafeConfigRepository
    let currentUser: AuthUser

    init(
        placeOrderUseCase: PlaceOrderUseCase,
        orderRepository: any OrderRepository,
        cafeConfigRepository: any CafeConfigRepository,
        currentUser: AuthUser
    ) {
        self.placeOrderUseCase = placeOrderUseCase
        self.orderRepository = orderRepository
        self.cafeConfigRepository = cafeConfigRepository
        self.currentUser = currentUser
    }

    var isOrderingAllowed: Bool {
        guard let config = cafeConfig else { return false }
        return Date().isWithinOrderingWindow(config: config)
    }

    var cartTotal: Double { cart.reduce(0) { $0 + $1.price } }
    var cartPoints: Int { cart.reduce(0) { $0 + $1.pointValue } }

    func addToCart(_ item: OrderItem) {
        cart.append(item)
    }

    func removeFromCart(at offsets: IndexSet) {
        cart.remove(atOffsets: offsets)
    }

    func placeOrder(requestedTime: Date) async {
        isLoading = true
        errorMessage = nil
        do {
            let order = try await placeOrderUseCase.execute(
                requestedReadyTime: requestedTime,
                items: cart,
                customerId: currentUser.id,
                customerName: currentUser.displayName
            )
            activeOrder = order
            cart = []
            observeOrder(id: order.id)
        } catch let error as OrderError {
            errorMessage = orderMessage(error)
        } catch let error as PaymentError {
            errorMessage = paymentMessage(error)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func observeOrder(id: String) {
        Task {
            for await updated in orderRepository.observeOrder(id: id) {
                activeOrder = updated
            }
        }
    }

    func loadCafeConfig() {
        Task {
            cafeConfig = try? await cafeConfigRepository.fetchConfig()
            for await config in cafeConfigRepository.observeConfig() {
                cafeConfig = config
            }
        }
    }

    private func orderMessage(_ error: OrderError) -> String {
        switch error {
        case .orderingWindowClosed: "Ordering is currently closed. Please check café hours."
        case .paymentFailed: "Payment failed. Your order was not placed."
        case .notFound: "Order not found."
        case .permissionDenied: "Permission denied."
        case .networkUnavailable: "No internet connection."
        case .unknown(let msg): msg
        }
    }

    private func paymentMessage(_ error: PaymentError) -> String {
        switch error {
        case .cardDeclined(let r): "Card declined: \(r)"
        case .insufficientFunds: "Insufficient funds."
        case .networkUnavailable: "No internet connection."
        case .cancelled: "Payment cancelled."
        case .unknown(let msg): msg
        }
    }
}
