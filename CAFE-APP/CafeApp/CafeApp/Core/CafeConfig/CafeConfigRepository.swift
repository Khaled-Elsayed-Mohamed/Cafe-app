import Foundation

protocol CafeConfigRepository {
    func fetchConfig() async throws -> CafeConfig
    func observeConfig() -> AsyncStream<CafeConfig>
}

enum CafeConfigError: Error {
    case configNotFound
    case networkUnavailable
    case unknown(String)
}
