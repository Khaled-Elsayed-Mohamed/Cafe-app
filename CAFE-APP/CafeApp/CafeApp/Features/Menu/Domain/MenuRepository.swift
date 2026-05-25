import Foundation

protocol MenuRepository {
    func fetchMenu() async throws -> [MenuItem]
    func fetchCachedMenu() -> [MenuItem]
    func observeMenuUpdates() -> AsyncStream<[MenuItem]>
    func fetchAllMenuItems() async throws -> [MenuItem]
    func saveMenuItem(_ item: MenuItem) async throws
    func deleteMenuItem(id: String) async throws
}

enum MenuError: Error {
    case networkUnavailable
    case decodingFailed
    case unknown(String)
}
