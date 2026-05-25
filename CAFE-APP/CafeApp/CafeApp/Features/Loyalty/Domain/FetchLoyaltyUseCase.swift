import Foundation

struct FetchLoyaltyUseCase {
    private let repository: any LoyaltyRepository

    init(repository: any LoyaltyRepository) {
        self.repository = repository
    }

    func execute(customerId: String) async throws -> (account: LoyaltyAccount, rewards: [Reward]) {
        async let account = repository.fetchAccount(customerId: customerId)
        async let rewards = repository.fetchRewards(customerId: customerId)
        return try await (account, rewards)
    }
}
