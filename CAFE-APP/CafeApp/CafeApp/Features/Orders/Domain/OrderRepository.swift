import Foundation

protocol OrderRepository {
    func createOrder(
        customerId: String,
        customerName: String,
        items: [OrderItem],
        requestedReadyTime: Date,
        paymentReference: String
    ) async throws -> Order

    func fetchOrder(id: String) async throws -> Order
    func observeOrder(id: String) -> AsyncStream<Order>
    func fetchTodayOrders(customerId: String) async throws -> [Order]
}

enum OrderError: Error {
    case notFound
    case permissionDenied
    case networkUnavailable
    case paymentFailed
    case orderingWindowClosed
    case unknown(String)
}
