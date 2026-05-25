import XCTest
import FirebaseCore
import FirebaseFirestore
@testable import CafeApp

final class FirebaseLoyaltyRepositoryTests: XCTestCase {

    var repository: FirebaseLoyaltyRepository!

    override func setUpWithError() throws {
        let settings = FirestoreSettings()
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        repository = FirebaseLoyaltyRepository()
    }

    func testFetchAccountForSeededUser() async throws {
        // Seed data includes a loyalty account for the test customer UID
        // Created by the onCreateUser Cloud Function trigger in the emulator
        let account = try await repository.fetchAccount(customerId: "test-uid-seed")
        XCTAssertFalse(account.membershipBarcode.isEmpty, "membershipBarcode should be set")
        XCTAssertGreaterThanOrEqual(account.totalPoints, 0)
    }

    func testObserveAccountEmitsValue() async throws {
        let stream = repository.observeAccount(customerId: "test-uid-seed")
        var observed: LoyaltyAccount?
        for await account in stream {
            observed = account
            break
        }
        XCTAssertNotNil(observed, "observeAccount should emit at least one value")
    }

    func testFetchPointTransactions() async throws {
        let transactions = try await repository.fetchPointTransactions(customerId: "test-uid-seed")
        XCTAssertGreaterThanOrEqual(transactions.count, 0)
    }
}
