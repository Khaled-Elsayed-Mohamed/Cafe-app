import Foundation

struct PlaceOrderUseCase {
    private let paymentRepository: any PaymentRepository
    private let orderRepository: any OrderRepository
    private let cafeConfigRepository: any CafeConfigRepository

    init(
        paymentRepository: any PaymentRepository,
        orderRepository: any OrderRepository,
        cafeConfigRepository: any CafeConfigRepository
    ) {
        self.paymentRepository = paymentRepository
        self.orderRepository = orderRepository
        self.cafeConfigRepository = cafeConfigRepository
    }

    func execute(
        requestedReadyTime: Date,
        items: [OrderItem],
        customerId: String,
        customerName: String
    ) async throws -> Order {
        let config = try await cafeConfigRepository.fetchConfig()

        guard requestedReadyTime.isWithinOrderingWindow(config: config) else {
            throw OrderError.orderingWindowClosed
        }

        let totalAmount = items.reduce(0.0) { $0 + $1.price }
        let paymentResult = try await paymentRepository.collectPayment(
            amount: totalAmount,
            currency: "USD"
        )

        switch paymentResult.status {
        case .succeeded:
            return try await orderRepository.createOrder(
                customerId: customerId,
                customerName: customerName,
                items: items,
                requestedReadyTime: requestedReadyTime,
                paymentReference: paymentResult.paymentReference
            )
        case .failed(let reason):
            throw OrderError.paymentFailed
        case .cancelled:
            throw PaymentError.cancelled
        }
    }
}
