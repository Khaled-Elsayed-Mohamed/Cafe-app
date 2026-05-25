import Foundation
import FirebaseMessaging
import UserNotifications
import FirebaseFirestore

final class FCMNotificationRepository: NotificationRepository {

    private let db = Firestore.firestore()

    func requestPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    }

    func registerDeviceToken(_ token: Data, forUserId userId: String) async throws {
        Messaging.messaging().apnsToken = token
        guard let fcmToken = try await Messaging.messaging().token() as String? else { return }
        try await db.collection("customers").document(userId).updateData([
            "fcmToken": fcmToken
        ])
    }

    func isPermissionGranted() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized ||
               settings.authorizationStatus == .provisional
    }
}
