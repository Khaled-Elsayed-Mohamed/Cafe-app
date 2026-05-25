import Foundation

/// Stub payment repository — Square SDK will be integrated in the payments phase.
final class StubPaymentRepository: PaymentRepository {
    func collectPayment(amount: Double, currency: String) async throws -> PaymentResult {
        throw PaymentError.unknown("Payments are not yet configured. Square SDK will be integrated in a future phase.")
    }
}
