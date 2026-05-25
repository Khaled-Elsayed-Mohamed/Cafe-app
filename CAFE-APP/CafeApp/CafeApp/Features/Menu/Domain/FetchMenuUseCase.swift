import Foundation

struct FetchMenuUseCase {
    private let repository: any MenuRepository

    init(repository: any MenuRepository) {
        self.repository = repository
    }

    func execute() async throws -> [MenuItem] {
        do {
            return try await repository.fetchMenu()
        } catch {
            let cached = repository.fetchCachedMenu()
            if cached.isEmpty { throw error }
            return cached
        }
    }
}
