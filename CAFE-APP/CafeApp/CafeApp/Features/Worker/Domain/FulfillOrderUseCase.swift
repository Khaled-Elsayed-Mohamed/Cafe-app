import Foundation

struct FulfillOrderUseCase {
    private let repository: any WorkerOrderRepository

    init(repository: any WorkerOrderRepository) {
        self.repository = repository
    }

    func acceptOrder(_ order: Order) async throws {
        guard order.status == .pending else {
            throw WorkerOrderError.invalidStatusTransition(from: order.status, to: .accepted)
        }
        try await repository.acceptOrder(id: order.id)
    }

    func checkOffItem(order: Order, itemIndex: Int) async throws {
        try await repository.checkOffItem(orderId: order.id, itemIndex: itemIndex)
        let allChecked = order.items.indices.filter { $0 != itemIndex }
            .allSatisfy { order.items[$0].isCheckedOff }
        let thisItemNowChecked = true
        if allChecked && thisItemNowChecked {
            try await repository.markOrderReady(id: order.id)
        }
    }

    func markOrderCompleted(_ order: Order) async throws {
        guard order.status == .ready else {
            throw WorkerOrderError.invalidStatusTransition(from: order.status, to: .completed)
        }
        try await repository.markOrderCompleted(id: order.id)
    }
}
