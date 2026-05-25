import Foundation
@testable import CafeApp

final class MockLoyaltyRepository: LoyaltyRepository {
    var stubbedAccount: LoyaltyAccount?
    var stubbedRewards: [Reward] = []
    var stubbedTransactions: [PointTransaction] = []
    var shouldThrow: LoyaltyError?

    func fetchAccount(customerId: String) async throws -> LoyaltyAccount {
        if let error = shouldThrow { throw error }
        return stubbedAccount ?? LoyaltyAccount(
            customerId: customerId, membershipBarcode: UUID().uuidString,
            totalPoints: 0, orderCount: 0
        )
    }

    func observeAccount(customerId: String) -> AsyncStream<LoyaltyAccount> {
        AsyncStream { continuation in
            if let account = stubbedAccount {
                continuation.yield(account)
            }
            continuation.finish()
        }
    }

    func fetchRewards(customerId: String) async throws -> [Reward] {
        if let error = shouldThrow { throw error }
        return stubbedRewards
    }

    func redeemReward(rewardId: String, customerId: String) async throws {
        if let error = shouldThrow { throw error }
        if let idx = stubbedRewards.firstIndex(where: { $0.id == rewardId }) {
            stubbedRewards[idx].redemptionStatus = .pendingRedemption
        }
    }

    func fetchPointTransactions(customerId: String) async throws -> [PointTransaction] {
        if let error = shouldThrow { throw error }
        return stubbedTransactions
    }
}
