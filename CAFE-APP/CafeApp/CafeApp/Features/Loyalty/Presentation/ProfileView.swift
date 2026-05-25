import SwiftUI

struct ProfileView: View {
    @State var viewModel: LoyaltyViewModel
    let currentUser: AuthUser
    let onSignOut: () async -> Void
    @State private var showRewards = false
    @State private var showBarcode = false
    @State private var showNotificationSettings = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                transactionsSection
                settingsSection
                signOutSection
            }
            .navigationTitle("Profile")
            .task { await viewModel.load(customerId: currentUser.id) }
            .navigationDestination(isPresented: $showRewards) {
                RewardsView(viewModel: viewModel, currentUser: currentUser)
            }
            .navigationDestination(isPresented: $showBarcode) {
                if let account = viewModel.account {
                    BarcodeView(membershipBarcode: account.membershipBarcode)
                }
            }
        }
    }

    private var accountSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading) {
                    Text(currentUser.displayName).font(.headline)
                    Text(currentUser.email).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let account = viewModel.account {
                    VStack(alignment: .trailing) {
                        Text("\(account.totalPoints)")
                            .font(.title2.bold())
                            .foregroundStyle(Color.accentColor)
                        Text("pts").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)

            Button(action: { showRewards = true }) {
                Label("My Rewards", systemImage: "gift")
            }

            Button(action: { showBarcode = true }) {
                Label("Membership Card", systemImage: "qrcode")
            }
        }
    }

    private var transactionsSection: some View {
        Section("Points History") {
            if viewModel.transactions.isEmpty {
                Text("No transactions yet.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(viewModel.transactions) { tx in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Order #\(tx.orderId.prefix(8).uppercased())")
                                .font(.subheadline)
                            Spacer()
                            Text("+\(tx.totalPointsEarned) pts")
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                        }
                        ForEach(tx.itemBreakdown, id: \.itemId) { item in
                            Text("  \(item.itemName): +\(item.pointsEarned) pts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(tx.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var settingsSection: some View {
        Section("Settings") {
            Button(action: { showNotificationSettings = true }) {
                Label("Notification Preferences", systemImage: "bell")
            }
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsView()
        }
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                Task { await onSignOut() }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }
}
