import Foundation

struct Order: Identifiable {
    let id: String
    let customerId: String
    let customerName: String
    var items: [OrderItem]
    let totalAmount: Double
    let totalPointsEarned: Int
    var status: OrderStatus
    let requestedReadyTime: Date
    let createdAt: Date
    var statusTimestamps: OrderStatusTimestamps
    var expiresAt: Date?
    var paymentReference: String?
}

enum OrderStatus: String, Codable {
    case pending
    case accepted
    case inProcess   = "in_process"
    case ready
    case completed
    case expired
}

struct OrderStatusTimestamps {
    let pending: Date
    let accepted: Date?
    let inProcess: Date?
    let ready: Date?
    let completed: Date?
    let expired: Date?
}
