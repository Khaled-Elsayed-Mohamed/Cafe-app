import Foundation
import FirebaseFirestore

final class FirebaseWorkerOrderRepository: WorkerOrderRepository {

    private let db = Firestore.firestore()

    func observeActiveOrders(date: String) -> AsyncStream<[Order]> {
        AsyncStream { continuation in
            let listener = db.collection("orders")
                .whereField("date", isEqualTo: date)
                .whereField("status", in: ["pending", "accepted", "in_process"])
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot else { return }
                    let orders = snapshot.documents.compactMap { doc -> Order? in
                        guard let data = doc.data() as? [String: Any] else { return nil }
                        return self.decode(id: doc.documentID, data: data)
                    }
                    continuation.yield(orders.sorted { $0.requestedReadyTime < $1.requestedReadyTime })
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func acceptOrder(id: String) async throws {
        try await db.collection("orders").document(id).updateData([
            "status": "accepted",
            "statusTimestamps.accepted": Timestamp(date: Date())
        ])
    }

    func checkOffItem(orderId: String, itemIndex: Int) async throws {
        try await db.collection("orders").document(orderId).updateData([
            "items.\(itemIndex).isCheckedOff": true
        ])
    }

    func markOrderReady(id: String) async throws {
        let expiryConfig = try await db.collection("cafe_config").document("default").getDocument()
        let timeoutMinutes = (expiryConfig.data()?["orderTimeoutMinutes"] as? Int) ?? 120
        let expiresAt = Date().addingTimeInterval(Double(timeoutMinutes) * 60)

        try await db.collection("orders").document(id).updateData([
            "status": "ready",
            "statusTimestamps.ready": Timestamp(date: Date()),
            "expiresAt": Timestamp(date: expiresAt)
        ])
    }

    func markOrderCompleted(id: String) async throws {
        try await db.collection("orders").document(id).updateData([
            "status": "completed",
            "statusTimestamps.completed": Timestamp(date: Date())
        ])
    }

    // MARK: - Decoding

    private func decode(id: String, data: [String: Any]) -> Order? {
        let customerId = data["customerId"] as? String ?? ""
        let customerName = data["customerName"] as? String ?? ""
        let totalAmount = data["totalAmount"] as? Double ?? 0
        let totalPoints = data["totalPointsEarned"] as? Int ?? 0
        let statusRaw = data["status"] as? String ?? "pending"
        let status = OrderStatus(rawValue: statusRaw) ?? .pending
        let requestedReadyTime = (data["requestedReadyTime"] as? Timestamp)?.dateValue() ?? Date()
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue()
        let paymentRef = data["paymentReference"] as? String

        let rawItems = data["items"] as? [[String: Any]] ?? []
        let items: [OrderItem] = rawItems.map { d in
            OrderItem(
                menuItemId: d["menuItemId"] as? String ?? "",
                name: d["name"] as? String ?? "",
                size: d["size"] as? String,
                specialInstructions: d["specialInstructions"] as? String,
                pointValue: d["pointValue"] as? Int ?? 0,
                price: d["price"] as? Double ?? 0,
                isCheckedOff: d["isCheckedOff"] as? Bool ?? false
            )
        }

        let timestamps = data["statusTimestamps"] as? [String: Timestamp] ?? [:]
        let statusTimestamps = OrderStatusTimestamps(
            pending: timestamps["pending"]?.dateValue() ?? createdAt,
            accepted: timestamps["accepted"]?.dateValue(),
            inProcess: timestamps["inProcess"]?.dateValue(),
            ready: timestamps["ready"]?.dateValue(),
            completed: timestamps["completed"]?.dateValue(),
            expired: timestamps["expired"]?.dateValue()
        )

        return Order(
            id: id, customerId: customerId, customerName: customerName,
            items: items, totalAmount: totalAmount, totalPointsEarned: totalPoints,
            status: status, requestedReadyTime: requestedReadyTime, createdAt: createdAt,
            statusTimestamps: statusTimestamps, expiresAt: expiresAt, paymentReference: paymentRef
        )
    }
}
