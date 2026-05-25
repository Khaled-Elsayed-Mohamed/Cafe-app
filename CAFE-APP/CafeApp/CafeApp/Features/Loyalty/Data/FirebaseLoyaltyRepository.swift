import Foundation
import FirebaseFirestore

final class FirebaseLoyaltyRepository: LoyaltyRepository {

    private let db = Firestore.firestore()

    func fetchAccount(customerId: String) async throws -> LoyaltyAccount {
        let doc = try await db.collection("loyalty_accounts").document(customerId).getDocument()
        guard let data = doc.data() else { throw LoyaltyError.accountNotFound }
        return decode(uid: customerId, data: data)
    }

    func observeAccount(customerId: String) -> AsyncStream<LoyaltyAccount> {
        AsyncStream { continuation in
            let listener = db.collection("loyalty_accounts").document(customerId)
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot, let data = snapshot.data() else { return }
                    continuation.yield(self.decode(uid: customerId, data: data))
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func fetchRewards(customerId: String) async throws -> [Reward] {
        let snapshot = try await db.collection("rewards")
            .whereField("customerId", isEqualTo: customerId)
            .order(by: "expiryDate", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { decodeReward(id: $0.documentID, data: $0.data()) }
    }

    func redeemReward(rewardId: String, customerId: String) async throws {
        try await db.collection("rewards").document(rewardId).updateData([
            "redemptionStatus": "pending_redemption",
            "redeemedAt": Timestamp(date: Date())
        ])
    }

    func fetchPointTransactions(customerId: String) async throws -> [PointTransaction] {
        let snapshot = try await db.collection("point_transactions")
            .whereField("customerId", isEqualTo: customerId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { decodeTransaction(id: $0.documentID, data: $0.data()) }
    }

    // MARK: - Decoding

    private func decode(uid: String, data: [String: Any]) -> LoyaltyAccount {
        LoyaltyAccount(
            customerId: uid,
            membershipBarcode: data["membershipBarcode"] as? String ?? "",
            totalPoints: data["totalPoints"] as? Int ?? 0,
            orderCount: data["orderCount"] as? Int ?? 0
        )
    }

    private func decodeReward(id: String, data: [String: Any]) -> Reward? {
        guard
            let customerId = data["customerId"] as? String,
            let typeRaw = data["type"] as? String,
            let type = RewardType(rawValue: typeRaw),
            let monetaryValue = data["monetaryValue"] as? Double,
            let claimDate = (data["claimDate"] as? Timestamp)?.dateValue(),
            let expiryDate = (data["expiryDate"] as? Timestamp)?.dateValue(),
            let statusRaw = data["redemptionStatus"] as? String,
            let status = RedemptionStatus(rawValue: statusRaw)
        else { return nil }

        return Reward(
            id: id,
            customerId: customerId,
            type: type,
            monetaryValue: monetaryValue,
            claimDate: claimDate,
            expiryDate: expiryDate,
            redemptionStatus: status,
            redeemedAt: (data["redeemedAt"] as? Timestamp)?.dateValue()
        )
    }

    private func decodeTransaction(id: String, data: [String: Any]) -> PointTransaction? {
        guard
            let orderId = data["orderId"] as? String,
            let total = data["totalPointsEarned"] as? Int,
            let sourceRaw = data["source"] as? String,
            let source = PointSource(rawValue: sourceRaw),
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else { return nil }

        let breakdown = (data["itemBreakdown"] as? [[String: Any]] ?? []).map { d in
            PointItem(
                itemId: d["itemId"] as? String ?? "",
                itemName: d["itemName"] as? String ?? "",
                pointsEarned: d["pointsEarned"] as? Int ?? 0
            )
        }

        return PointTransaction(
            id: id,
            orderId: orderId,
            itemBreakdown: breakdown,
            totalPointsEarned: total,
            source: source,
            createdAt: createdAt
        )
    }
}
