import Foundation
import Observation

@Observable
final class WorkerOrderViewModel {
    var activeOrders: [Order] = []
    var isLoading = false
    var errorMessage: String?

    private let fulfillOrderUseCase: FulfillOrderUseCase
    private let repository: any WorkerOrderRepository

    init(fulfillOrderUseCase: FulfillOrderUseCase, repository: any WorkerOrderRepository) {
        self.fulfillOrderUseCase = fulfillOrderUseCase
        self.repository = repository
    }

    func observeOrders() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        Task {
            for await orders in repository.observeActiveOrders(date: today) {
                activeOrders = orders
            }
        }
    }

    func accept(order: Order) async {
        do {
            try await fulfillOrderUseCase.acceptOrder(order)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkOff(order: Order, itemIndex: Int) async {
        do {
            try await fulfillOrderUseCase.checkOffItem(order: order, itemIndex: itemIndex)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markCompleted(order: Order) async {
        do {
            try await fulfillOrderUseCase.markOrderCompleted(order)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
