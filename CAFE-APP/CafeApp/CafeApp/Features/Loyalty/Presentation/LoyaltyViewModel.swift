import Foundation
import Observation

@Observable
final class LoyaltyViewModel {
    var account: LoyaltyAccount?
    var rewards: [Reward] = []
    var transactions: [PointTransaction] = []
    var isLoading = false
    var errorMessage: String?

    private let repository: any LoyaltyRepository
    private let fetchUseCase: FetchLoyaltyUseCase
    private let redeemUseCase: RedeemRewardUseCase

    init(repository: any LoyaltyRepository) {
        self.repository = repository
        self.fetchUseCase = FetchLoyaltyUseCase(repository: repository)
        self.redeemUseCase = RedeemRewardUseCase(repository: repository)
    }

    func load(customerId: String) async {
        isLoading = true
        do {
            let (acc, rws) = try await fetchUseCase.execute(customerId: customerId)
            account = acc
            rewards = rws
            transactions = try await repository.fetchPointTransactions(customerId: customerId)
            observeAccount(customerId: customerId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func redeemReward(id: String, customerId: String) async {
        guard let reward = rewards.first(where: { $0.id == id }) else { return }
        do {
            try await redeemUseCase.execute(reward: reward, customerId: customerId)
            if let idx = rewards.firstIndex(where: { $0.id == id }) {
                rewards[idx].redemptionStatus = .pendingRedemption
            }
        } catch let error as LoyaltyError {
            errorMessage = loyaltyMessage(error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func observeAccount(customerId: String) {
        Task {
            for await updated in repository.observeAccount(customerId: customerId) {
                account = updated
            }
        }
    }

    private func loyaltyMessage(_ error: LoyaltyError) -> String {
        switch error {
        case .accountNotFound: "Loyalty account not found."
        case .alreadyRedeemed: "Reward already redeemed."
        case .rewardExpired: "This reward has expired."
        case .rewardNotActive: "This reward is not currently active."
        case .networkUnavailable: "No internet connection."
        case .unknown(let msg): msg
        }
    }
}
