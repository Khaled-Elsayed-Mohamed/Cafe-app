import Foundation
@testable import CafeApp

final class MockWorkerOrderRepository: WorkerOrderRepository {
    var stubbedOrders: [Order] = []
    var shouldThrow: WorkerOrderError?

    func observeActiveOrders(date: String) -> AsyncStream<[Order]> {
        AsyncStream { continuation in
            continuation.yield(stubbedOrders)
            continuation.finish()
        }
    }

    func acceptOrder(id: String) async throws {
        if let error = shouldThrow { throw error }
        if let idx = stubbedOrders.firstIndex(where: { $0.id == id }) {
            stubbedOrders[idx].status = .accepted
        }
    }

    func checkOffItem(orderId: String, itemIndex: Int) async throws {
        if let error = shouldThrow { throw error }
        if let idx = stubbedOrders.firstIndex(where: { $0.id == orderId }) {
            stubbedOrders[idx].items[itemIndex].isCheckedOff = true
        }
    }

    func markOrderReady(id: String) async throws {
        if let error = shouldThrow { throw error }
        if let idx = stubbedOrders.firstIndex(where: { $0.id == id }) {
            stubbedOrders[idx].status = .ready
        }
    }

    func markOrderCompleted(id: String) async throws {
        if let error = shouldThrow { throw error }
        if let idx = stubbedOrders.firstIndex(where: { $0.id == id }) {
            stubbedOrders[idx].status = .completed
        }
    }
}
