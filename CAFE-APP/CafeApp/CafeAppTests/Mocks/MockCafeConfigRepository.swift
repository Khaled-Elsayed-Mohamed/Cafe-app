import Foundation
@testable import CafeApp

final class MockCafeConfigRepository: CafeConfigRepository {
    var stubbedConfig = CafeConfig(
        openTime: "07:00",
        closeTime: "20:00",
        orderCutoffMinutes: 15,
        orderTimeoutMinutes: 120,
        timezone: TimeZone(identifier: "America/New_York") ?? .current
    )
    var shouldThrow: CafeConfigError?

    func fetchConfig() async throws -> CafeConfig {
        if let error = shouldThrow { throw error }
        return stubbedConfig
    }

    func observeConfig() -> AsyncStream<CafeConfig> {
        AsyncStream { continuation in
            continuation.yield(stubbedConfig)
            continuation.finish()
        }
    }
}
