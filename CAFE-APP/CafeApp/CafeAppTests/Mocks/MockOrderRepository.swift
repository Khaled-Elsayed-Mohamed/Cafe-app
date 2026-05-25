import Foundation
@testable import CafeApp

final class MockOrderRepository: OrderRepository {
    var stubbedOrders: [Order] = []
    var shouldThrow: OrderError?

    func createOrder(
        customerId: String,
        customerName: String,
        items: [OrderItem],
        requestedReadyTime: Date,
        paymentReference: String
    ) async throws -> Order {
        if let error = shouldThrow { throw error }
        let order = Order(
            id: UUID().uuidString,
            customerId: customerId,
            customerName: customerName,
            items: items,
            totalAmount: items.reduce(0) { $0 + $1.price },
            totalPointsEarned: items.reduce(0) { $0 + $1.pointValue },
            status: .pending,
            requestedReadyTime: requestedReadyTime,
            createdAt: Date(),
            statusTimestamps: OrderStatusTimestamps(
                pending: Date(), accepted: nil, inProcess: nil,
                ready: nil, completed: nil, expired: nil
            )
        )
        stubbedOrders.append(order)
        return order
    }

    func fetchOrder(id: String) async throws -> Order {
        if let error = shouldThrow { throw error }
        guard let order = stubbedOrders.first(where: { $0.id == id }) else {
            throw OrderError.notFound
        }
        return order
    }

    func observeOrder(id: String) -> AsyncStream<Order> {
        AsyncStream { continuation in
            if let order = stubbedOrders.first(where: { $0.id == id }) {
                continuation.yield(order)
            }
            continuation.finish()
        }
    }

    func fetchTodayOrders(customerId: String) async throws -> [Order] {
        if let error = shouldThrow { throw error }
        return stubbedOrders.filter { $0.customerId == customerId }
    }
}
