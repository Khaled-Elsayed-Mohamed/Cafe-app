import Foundation

protocol NotificationRepository {
    func requestPermission() async throws -> Bool
    func registerDeviceToken(_ token: Data, forUserId userId: String) async throws
    func isPermissionGranted() async -> Bool
}

enum NotificationError: Error {
    case permissionDenied
    case registrationFailed(String)
    case unknown(String)
}
