import Foundation
import FirebaseAuth
import FirebaseFirestore

struct DependencyContainer {
    let authRepository: any AuthRepository
    let menuRepository: any MenuRepository
    let orderRepository: any OrderRepository
    let paymentRepository: any PaymentRepository
    let workerOrderRepository: any WorkerOrderRepository
    let cafeConfigRepository: any CafeConfigRepository
    let networkMonitorRepository: any NetworkMonitorRepository
    // Wired in Phase 5 after their protocols and implementations exist
    var loyaltyRepository: (any LoyaltyRepository)?
    var notificationRepository: (any NotificationRepository)?

    static func live(useEmulator: Bool = false) -> DependencyContainer {
        if useEmulator {
            Auth.auth().useEmulator(withHost: "localhost", port: 9099)
            let settings = FirestoreSettings()
            settings.host = "localhost:8080"
            settings.cacheSettings = MemoryCacheSettings()
            settings.isSSLEnabled = false
            Firestore.firestore().settings = settings
        }

        return DependencyContainer(
            authRepository: FirebaseAuthRepository(),
            menuRepository: FirebaseMenuRepository(),
            orderRepository: FirebaseOrderRepository(),
            paymentRepository: StubPaymentRepository(),
            workerOrderRepository: FirebaseWorkerOrderRepository(),
            cafeConfigRepository: FirebaseCafeConfigRepository(),
            networkMonitorRepository: NWNetworkMonitor(),
            loyaltyRepository: FirebaseLoyaltyRepository(),
            notificationRepository: FCMNotificationRepository()
        )
    }
}
