import Foundation

protocol NetworkMonitorRepository {
    func observeConnectivity() -> AsyncStream<Bool>
}
