import Foundation
import FirebaseFirestore

final class FirebaseMenuRepository: MenuRepository {

    private let db = Firestore.firestore()
    private let cacheKey = "menu_cache"

    func fetchMenu() async throws -> [MenuItem] {
        do {
            let snapshot = try await db.collection("menu_items")
                .whereField("isAvailable", isEqualTo: true)
                .getDocuments()
            let items = try snapshot.documents.map { try decode($0) }
            if let data = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(data, forKey: cacheKey)
            }
            return items
        } catch {
            throw MenuError.networkUnavailable
        }
    }

    func fetchCachedMenu() -> [MenuItem] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let items = try? JSONDecoder().decode([MenuItem].self, from: data) else {
            return []
        }
        return items
    }

    func observeMenuUpdates() -> AsyncStream<[MenuItem]> {
        AsyncStream { continuation in
            let listener = db.collection("menu_items")
                .whereField("isAvailable", isEqualTo: true)
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot else { return }
                    let items = snapshot.documents.compactMap { try? self.decode($0) }
                    continuation.yield(items)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func fetchAllMenuItems() async throws -> [MenuItem] {
        do {
            let snapshot = try await db.collection("menu_items").getDocuments()
            return try snapshot.documents.map { try decode($0) }
        } catch {
            throw MenuError.networkUnavailable
        }
    }

    func saveMenuItem(_ item: MenuItem) async throws {
        var data: [String: Any] = [
            "name": item.name,
            "description": item.description,
            "inStorePrice": item.inStorePrice,
            "isAppOnly": item.isAppOnly,
            "allergens": item.allergens,
            "pointValue": item.pointValue,
            "category": item.category.rawValue,
            "isAvailable": item.isAvailable,
            "sizes": item.sizes.map { ["name": $0.name, "price": $0.price] }
        ]
        if let appPrice = item.appPrice { data["appPrice"] = appPrice }
        try await db.collection("menu_items").document(item.id).setData(data)
    }

    func deleteMenuItem(id: String) async throws {
        try await db.collection("menu_items").document(id).delete()
    }

    private func decode(_ doc: QueryDocumentSnapshot) throws -> MenuItem {
        let data = doc.data()
        guard
            let name = data["name"] as? String,
            let description = data["description"] as? String,
            let inStorePrice = data["inStorePrice"] as? Double,
            let isAppOnly = data["isAppOnly"] as? Bool,
            let allergens = data["allergens"] as? [String],
            let pointValue = data["pointValue"] as? Int,
            let categoryRaw = data["category"] as? String,
            let category = MenuCategory(rawValue: categoryRaw),
            let isAvailable = data["isAvailable"] as? Bool
        else {
            throw MenuError.decodingFailed
        }
        let sizes: [ItemSize] = (data["sizes"] as? [[String: Any]] ?? []).compactMap { sizeMap in
            guard let name = sizeMap["name"] as? String,
                  let price = sizeMap["price"] as? Double else { return nil }
            return ItemSize(name: name, price: price)
        }
        return MenuItem(
            id: doc.documentID,
            name: name,
            description: description,
            inStorePrice: inStorePrice,
            appPrice: data["appPrice"] as? Double,
            isAppOnly: isAppOnly,
            allergens: allergens,
            pointValue: pointValue,
            category: category,
            isAvailable: isAvailable,
            sizes: sizes
        )
    }
}
