import Foundation
import FirebaseFirestore

final class FirebaseCafeConfigRepository: CafeConfigRepository {

    private let db = Firestore.firestore()

    func fetchConfig() async throws -> CafeConfig {
        let snapshot = try await db.collection("cafe_config").document("default").getDocument()
        return try decode(snapshot)
    }

    func observeConfig() -> AsyncStream<CafeConfig> {
        AsyncStream { continuation in
            let listener = db.collection("cafe_config").document("default")
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot, snapshot.exists,
                          let config = try? self.decode(snapshot) else { return }
                    continuation.yield(config)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    private func decode(_ snapshot: DocumentSnapshot) throws -> CafeConfig {
        guard let data = snapshot.data() else {
            throw CafeConfigError.configNotFound
        }
        let openTime = data["openTime"] as? String ?? "07:00"
        let closeTime = data["closeTime"] as? String ?? "20:00"
        let cutoff = data["orderCutoffMinutes"] as? Int ?? 15
        let timeout = data["orderTimeoutMinutes"] as? Int ?? 120
        let tzId = data["timezone"] as? String ?? "America/New_York"
        let tz = TimeZone(identifier: tzId) ?? .current
        return CafeConfig(
            openTime: openTime,
            closeTime: closeTime,
            orderCutoffMinutes: cutoff,
            orderTimeoutMinutes: timeout,
            timezone: tz
        )
    }
}
