// NotificationRepository.swift
// Architectural contract — Domain layer protocol.
// Concrete implementations live in Features/Notifications/Data/ only.
// No Firebase SDK or APNs types permitted in this file.

import Foundation

protocol NotificationRepository {
    /// Requests APNs permission from the user and registers with FCM.
    /// Returns true if the user granted permission (FR-017).
    func requestPermission() async throws -> Bool

    /// Registers the FCM device token in Firestore (customers/{uid}/fcmToken).
    /// Called on successful APNs registration and on each app launch.
    func registerDeviceToken(_ token: Data, forUserId userId: String) async throws

    /// Returns whether the customer has granted push notification permission.
    func isPermissionGranted() async -> Bool
}

// MARK: - Domain Errors

enum NotificationError: Error {
    case permissionDenied
    case registrationFailed(String)
    case unknown(String)
}
