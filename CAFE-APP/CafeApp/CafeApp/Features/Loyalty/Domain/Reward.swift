import Foundation

struct Reward: Identifiable {
    let id: String
    let customerId: String
    let type: RewardType
    let monetaryValue: Double
    let claimDate: Date
    let expiryDate: Date
    var redemptionStatus: RedemptionStatus
    let redeemedAt: Date?
}

enum RewardType: String, Codable {
    case freeCoffee = "free_coffee"
}

enum RedemptionStatus: String, Codable {
    case unredeemed
    case pendingRedemption = "pending_redemption"
    case redeemed
}

extension Reward {
    var isActive: Bool {
        redemptionStatus == .unredeemed && expiryDate > Date()
    }
}
