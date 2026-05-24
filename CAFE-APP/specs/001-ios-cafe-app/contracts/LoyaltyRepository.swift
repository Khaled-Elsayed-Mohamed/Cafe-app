// LoyaltyRepository.swift
// Architectural contract — Domain layer protocol.
// Concrete implementations live in Features/Loyalty/Data/ only.
// No Firebase imports permitted in this file.

import Foundation

protocol LoyaltyRepository {
    /// Fetches the loyalty account for a customer. Called on profile load.
    func fetchAccount(customerId: String) async throws -> LoyaltyAccount

    /// Emits the loyalty account in real-time — used by ProfileView to show
    /// updated points immediately after a transaction (SC-003).
    func observeAccount(customerId: String) -> AsyncStream<LoyaltyAccount>

    /// Fetches all rewards for a customer, sorted by claimDate descending.
    func fetchRewards(customerId: String) async throws -> [Reward]

    /// Marks a reward as pending redemption (FR-021).
    /// Throws LoyaltyError.alreadyRedeemed if status is not .unredeemed.
    func redeemReward(rewardId: String, customerId: String) async throws

    /// Fetches point transaction history for a customer.
    func fetchPointTransactions(customerId: String) async throws -> [PointTransaction]
}

// MARK: - Supporting Types

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
    case preOrder  = "pre_order"
    case inStore   = "in_store"   // Phase 5 only
}

// MARK: - Domain Errors

enum LoyaltyError: Error {
    case accountNotFound
    case alreadyRedeemed
    case rewardExpired
    case networkUnavailable
    case unknown(String)
}
