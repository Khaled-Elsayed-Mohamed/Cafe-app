// PaymentRepository.swift
// Architectural contract — Domain layer protocol.
// Concrete implementations live in Features/Orders/Data/ only.
// No Square SDK types permitted in this file — all types are domain-defined.

import Foundation

protocol PaymentRepository {
    /// Presents the Square In-App Payments card entry flow and returns a payment nonce.
    /// The nonce is sent server-side (Firebase callable function) to complete the Square charge.
    /// Returns a PaymentResult with the opaque paymentReference on success.
    /// On failure, returns PaymentResult with status .failed — no order must be created (FR-005).
    func collectPayment(amount: Double, currency: String) async throws -> PaymentResult
}

// MARK: - Domain Errors

enum PaymentError: Error {
    case cardDeclined(reason: String)
    case insufficientFunds
    case networkUnavailable
    case cancelled
    case unknown(String)
}
