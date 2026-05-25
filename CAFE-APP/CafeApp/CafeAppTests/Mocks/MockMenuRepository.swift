import Foundation
@testable import CafeApp

final class MockMenuRepository: MenuRepository {
    var stubbedItems: [MenuItem] = []
    var shouldThrow: MenuError?

    func fetchMenu() async throws -> [MenuItem] {
        if let error = shouldThrow { throw error }
        return stubbedItems
    }

    func fetchCachedMenu() -> [MenuItem] { stubbedItems }

    func observeMenuUpdates() -> AsyncStream<[MenuItem]> {
        AsyncStream { continuation in
            continuation.yield(stubbedItems)
            continuation.finish()
        }
    }

    func fetchAllMenuItems() async throws -> [MenuItem] {
        if let error = shouldThrow { throw error }
        return stubbedItems
    }

    func saveMenuItem(_ item: MenuItem) async throws {
        if let error = shouldThrow { throw error }
        if let idx = stubbedItems.firstIndex(where: { $0.id == item.id }) {
            stubbedItems[idx] = item
        } else {
            stubbedItems.append(item)
        }
    }

    func deleteMenuItem(id: String) async throws {
        if let error = shouldThrow { throw error }
        stubbedItems.removeAll { $0.id == id }
    }
}
