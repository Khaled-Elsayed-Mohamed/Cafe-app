import Foundation

protocol LoyaltyRepository {
    func fetchAccount(customerId: String) async throws -> LoyaltyAccount
    func observeAccount(customerId: String) -> AsyncStream<LoyaltyAccount>
    func fetchRewards(customerId: String) async throws -> [Reward]
    func redeemReward(rewardId: String, customerId: String) async throws
    func fetchPointTransactions(customerId: String) async throws -> [PointTransaction]
}

struct PointTransaction: Identifiable {
    let id: String
    let orderId: String
    let itemBreakdown: [PointItem]
    let totalPointsEarned: Int
    let source: PointSource
    let createdAt: Date
}

struct PointItem {
    let itemId: String
    let itemName: String
    let pointsEarned: Int
}

enum PointSource: String, Codable {
    case preOrder = "pre_order"
    case inStore  = "in_store"
}

enum LoyaltyError: Error {
    case accountNotFound
    case alreadyRedeemed
    case rewardExpired
    case rewardNotActive
    case networkUnavailable
    case unknown(String)
}
