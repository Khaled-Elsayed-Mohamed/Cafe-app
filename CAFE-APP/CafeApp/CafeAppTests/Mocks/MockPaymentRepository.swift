import Foundation
@testable import CafeApp

final class MockPaymentRepository: PaymentRepository {
    var stubbedResult: PaymentResult = PaymentResult(paymentReference: "mock-ref", status: .succeeded)
    var shouldThrow: PaymentError?

    func collectPayment(amount: Double, currency: String) async throws -> PaymentResult {
        if let error = shouldThrow { throw error }
        return stubbedResult
    }
}
