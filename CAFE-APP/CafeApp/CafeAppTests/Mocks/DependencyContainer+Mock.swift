import Foundation
@testable import CafeApp

extension DependencyContainer {
    static func mock() -> DependencyContainer {
        DependencyContainer(
            authRepository: MockAuthRepository(),
            menuRepository: MockMenuRepository(),
            orderRepository: MockOrderRepository(),
            paymentRepository: MockPaymentRepository(),
            workerOrderRepository: MockWorkerOrderRepository(),
            cafeConfigRepository: MockCafeConfigRepository(),
            networkMonitorRepository: MockNetworkMonitorRepository(),
            loyaltyRepository: nil,
            notificationRepository: nil
        )
    }
}
