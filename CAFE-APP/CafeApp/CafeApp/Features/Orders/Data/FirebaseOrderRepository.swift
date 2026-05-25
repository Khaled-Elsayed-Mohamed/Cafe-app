import Foundation
import FirebaseFirestore

final class FirebaseOrderRepository: OrderRepository {

    private let db = Firestore.firestore()

    func createOrder(
        customerId: String,
        customerName: String,
        items: [OrderItem],
        requestedReadyTime: Date,
        paymentReference: String
    ) async throws -> Order {
        let ref = db.collection("orders").document()
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: now)

        let itemDocs: [[String: Any]] = items.map { item in
            var d: [String: Any] = [
                "menuItemId": item.menuItemId,
                "name": item.name,
                "pointValue": item.pointValue,
                "price": item.price,
                "quantity": item.quantity,
                "isCheckedOff": false
            ]
            if let size = item.size { d["size"] = size }
            if let inst = item.specialInstructions { d["specialInstructions"] = inst }
            return d
        }

        let data: [String: Any] = [
            "id": ref.documentID,
            "customerId": customerId,
            "customerName": customerName,
            "items": itemDocs,
            "totalAmount": items.reduce(0) { $0 + $1.lineTotal },
            "totalPointsEarned": items.reduce(0) { $0 + $1.linePoints },
            "status": OrderStatus.pending.rawValue,
            "requestedReadyTime": Timestamp(date: requestedReadyTime),
            "paymentReference": paymentReference,
            "statusTimestamps": ["pending": Timestamp(date: now)],
            "date": dateStr,
            "createdAt": Timestamp(date: now)
        ]

        try await ref.setData(data)
        return Order(
            id: ref.documentID,
            customerId: customerId,
            customerName: customerName,
            items: items,
            totalAmount: items.reduce(0) { $0 + $1.lineTotal },
            totalPointsEarned: items.reduce(0) { $0 + $1.linePoints },
            status: .pending,
            requestedReadyTime: requestedReadyTime,
            createdAt: now,
            statusTimestamps: OrderStatusTimestamps(
                pending: now, accepted: nil, inProcess: nil,
                ready: nil, completed: nil, expired: nil
            ),
            expiresAt: nil,
            paymentReference: paymentReference
        )
    }

    func fetchOrder(id: String) async throws -> Order {
        let doc = try await db.collection("orders").document(id).getDocument()
        guard doc.exists else { throw OrderError.notFound }
        return try decode(doc)
    }

    func observeOrder(id: String) -> AsyncStream<Order> {
        AsyncStream { continuation in
            let listener = db.collection("orders").document(id)
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot, snapshot.exists,
                          let order = try? self.decode(snapshot) else { return }
                    continuation.yield(order)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func fetchTodayOrders(customerId: String) async throws -> [Order] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        let snapshot = try await db.collection("orders")
            .whereField("customerId", isEqualTo: customerId)
            .whereField("date", isEqualTo: today)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? decode($0) }
    }

    // MARK: - Decoding

    private func decode(_ doc: DocumentSnapshot) throws -> Order {
        guard let data = doc.data() else { throw OrderError.notFound }
        let id = doc.documentID
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
                quantity: d["quantity"] as? Int ?? 1,
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
