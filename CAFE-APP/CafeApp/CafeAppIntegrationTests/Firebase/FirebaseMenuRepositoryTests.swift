import XCTest
import FirebaseCore
import FirebaseFirestore
@testable import CafeApp

final class FirebaseMenuRepositoryTests: XCTestCase {

    var repository: FirebaseMenuRepository!

    override func setUpWithError() throws {
        let settings = FirestoreSettings()
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        repository = FirebaseMenuRepository()
    }

    func testFetchMenuReturnsItems() async throws {
        let items = try await repository.fetchMenu()
        XCTAssertFalse(items.isEmpty, "Menu should have items when emulator is seeded")
    }

    func testFetchCachedMenuAfterFetch() async throws {
        _ = try await repository.fetchMenu()
        let cached = repository.fetchCachedMenu()
        XCTAssertFalse(cached.isEmpty, "Cached menu should be populated after a successful fetch")
    }

    func testAllReturnedItemsAreAvailable() async throws {
        let items = try await repository.fetchMenu()
        XCTAssertTrue(items.allSatisfy { $0.isAvailable }, "fetchMenu should only return available items")
    }
}
