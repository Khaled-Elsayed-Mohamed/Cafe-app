import XCTest
import FirebaseCore
import FirebaseFirestore
@testable import CafeApp

final class FirebaseOrderRepositoryTests: XCTestCase {

    var repository: FirebaseOrderRepository!

    override func setUpWithError() throws {
        let settings = FirestoreSettings()
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        repository = FirebaseOrderRepository()
    }

    func testCreateOrderAndFetchById() async throws {
        let item = OrderItem(
            menuItemId: "item001",
            name: "Espresso",
            size: "Medium",
            specialInstructions: nil,
            pointValue: 5,
            price: 3.25,
            isCheckedOff: false
        )

        let requestedTime = Date().addingTimeInterval(30 * 60)
        let order = try await repository.createOrder(
            customerId: "test-customer",
            customerName: "Test Customer",
            items: [item],
            requestedReadyTime: requestedTime,
            paymentReference: "test-payment-ref"
        )

        XCTAssertFalse(order.id.isEmpty)
        XCTAssertEqual(order.status, .pending)
        XCTAssertEqual(order.items.count, 1)

        let fetched = try await repository.fetchOrder(id: order.id)
        XCTAssertEqual(fetched.id, order.id)
        XCTAssertEqual(fetched.customerId, "test-customer")
    }

    func testObserveOrderEmitsInitialState() async throws {
        let item = OrderItem(
            menuItemId: "item001",
            name: "Espresso",
            size: nil,
            specialInstructions: nil,
            pointValue: 5,
            price: 3.25,
            isCheckedOff: false
        )

        let order = try await repository.createOrder(
            customerId: "test-customer-2",
            customerName: "Test Customer 2",
            items: [item],
            requestedReadyTime: Date().addingTimeInterval(30 * 60),
            paymentReference: "test-ref-2"
        )

        var observed: Order?
        let stream = repository.observeOrder(id: order.id)
        for await o in stream {
            observed = o
            break
        }

        XCTAssertNotNil(observed)
        XCTAssertEqual(observed?.id, order.id)
    }
}
