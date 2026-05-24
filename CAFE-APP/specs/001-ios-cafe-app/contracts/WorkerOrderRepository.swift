// WorkerOrderRepository.swift
// Architectural contract — Domain layer protocol.
// Concrete implementations live in Features/Worker/Data/ only.
// No Firebase imports permitted in this file.

import Foundation

protocol WorkerOrderRepository {
    /// Emits the list of active orders for today (status: pending, accepted, in_process)
    /// in real-time without manual refresh (FR-010). New orders must appear within 1 second (SC-004).
    func observeActiveOrders(date: String) -> AsyncStream<[Order]>

    /// Transitions an order from .pending to .accepted (US3 scenario 3).
    func acceptOrder(id: String) async throws

    /// Marks a single item within an order as checked off (FR-011).
    /// If this is the last unchecked item, the caller (FulfillOrderUseCase)
    /// invokes markOrderReady immediately after (FR-012).
    func checkOffItem(orderId: String, itemIndex: Int) async throws

    /// Transitions order status to .ready and records the readyAt timestamp.
    /// The push notification is triggered server-side by the Firestore Cloud Function.
    func markOrderReady(id: String) async throws

    /// Transitions order status to .completed (worker confirms pickup).
    func markOrderCompleted(id: String) async throws
}

// MARK: - Domain Errors

enum WorkerOrderError: Error {
    case orderNotFound
    case invalidStatusTransition(from: OrderStatus, to: OrderStatus)
    case networkUnavailable
    case unknown(String)
}
