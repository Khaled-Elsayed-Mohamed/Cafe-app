import Foundation

protocol WorkerOrderRepository {
    func observeActiveOrders(date: String) -> AsyncStream<[Order]>
    func acceptOrder(id: String) async throws
    func checkOffItem(orderId: String, itemIndex: Int) async throws
    func markOrderReady(id: String) async throws
    func markOrderCompleted(id: String) async throws
}

enum WorkerOrderError: Error {
    case orderNotFound
    case invalidStatusTransition(from: OrderStatus, to: OrderStatus)
    case networkUnavailable
    case unknown(String)
}
