import Foundation
@testable import CafeApp

final class MockNotificationRepository: NotificationRepository {
    var stubbedPermissionGranted = true
    var shouldThrow: NotificationError?
    var registeredTokens: [(Data, String)] = []

    func requestPermission() async throws -> Bool {
        if let error = shouldThrow { throw error }
        return stubbedPermissionGranted
    }

    func registerDeviceToken(_ token: Data, forUserId userId: String) async throws {
        if let error = shouldThrow { throw error }
        registeredTokens.append((token, userId))
    }

    func isPermissionGranted() async -> Bool { stubbedPermissionGranted }
}
