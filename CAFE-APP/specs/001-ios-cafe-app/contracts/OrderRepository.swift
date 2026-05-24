// OrderRepository.swift
// Architectural contract — Domain layer protocol.
// Concrete implementations live in Features/Orders/Data/ only.
// No Firebase imports permitted in this file.

import Foundation

protocol OrderRepository {
    /// Creates a new order document in Firestore after payment is confirmed.
    /// Must only be called after PaymentRepository.confirmPayment succeeds (FR-005).
    func createOrder(
        customerId: String,
        customerName: String,
        items: [OrderItem],
        requestedReadyTime: Date,
        paymentReference: String
    ) async throws -> Order

    /// Fetches a single order by ID.
    func fetchOrder(id: String) async throws -> Order

    /// Emits order updates in real-time. Used by OrderTrackingView on the customer side.
    func observeOrder(id: String) -> AsyncStream<Order>

    /// Fetches the current customer's orders for today, sorted by createdAt descending.
    func fetchTodayOrders(customerId: String) async throws -> [Order]
}

// MARK: - Domain Errors

enum OrderError: Error {
    case notFound
    case permissionDenied
    case networkUnavailable
    case unknown(String)
}
