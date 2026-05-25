import Foundation

protocol PaymentRepository {
    func collectPayment(amount: Double, currency: String) async throws -> PaymentResult
}

struct PaymentResult {
    let paymentReference: String
    let status: PaymentStatus
}

enum PaymentStatus {
    case succeeded
    case failed(reason: String)
    case cancelled
}

enum PaymentError: Error {
    case cardDeclined(reason: String)
    case insufficientFunds
    case networkUnavailable
    case cancelled
    case unknown(String)
}
