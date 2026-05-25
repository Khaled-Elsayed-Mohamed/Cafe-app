import Foundation
import Network

final class NWNetworkMonitor: NetworkMonitorRepository {

    func observeConnectivity() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.cafeapp.networkmonitor")

            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }

            continuation.onTermination = { _ in
                monitor.cancel()
            }

            monitor.start(queue: queue)
        }
    }
}
