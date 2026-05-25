import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPermissionGranted = false
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isLoading {
                        ProgressView()
                    } else if isPermissionGranted {
                        Label("Notifications Enabled", systemImage: "bell.fill")
                            .foregroundStyle(.green)
                        Text("You'll receive a push notification when your order is ready for pickup.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Notifications Disabled", systemImage: "bell.slash")
                            .foregroundStyle(.secondary)
                        Text("Enable notifications in iOS Settings to receive order-ready alerts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                isPermissionGranted = settings.authorizationStatus == .authorized
                isLoading = false
            }
        }
    }
}
