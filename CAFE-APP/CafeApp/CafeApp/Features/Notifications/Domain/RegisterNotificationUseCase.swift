import Foundation

struct RegisterNotificationUseCase {
    private let repository: any NotificationRepository

    init(repository: any NotificationRepository) {
        self.repository = repository
    }

    func execute(token: Data, userId: String) async {
        let granted = await repository.isPermissionGranted()
        guard granted else { return }
        try? await repository.registerDeviceToken(token, forUserId: userId)
    }

    func requestAndRegister(token: Data?, userId: String) async throws {
        _ = try await repository.requestPermission()
        if let token {
            try await repository.registerDeviceToken(token, forUserId: userId)
        }
    }
}
