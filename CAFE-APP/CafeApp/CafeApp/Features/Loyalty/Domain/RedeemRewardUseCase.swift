import Foundation

struct RedeemRewardUseCase {
    private let repository: any LoyaltyRepository

    init(repository: any LoyaltyRepository) {
        self.repository = repository
    }

    func execute(reward: Reward, customerId: String) async throws {
        guard reward.isActive else {
            throw LoyaltyError.rewardNotActive
        }
        try await repository.redeemReward(rewardId: reward.id, customerId: customerId)
    }
}
