import Foundation
@testable import CafeApp

final class MockNetworkMonitorRepository: NetworkMonitorRepository {
    var stubbedIsConnected = true

    func observeConnectivity() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(stubbedIsConnected)
            continuation.finish()
        }
    }
}
