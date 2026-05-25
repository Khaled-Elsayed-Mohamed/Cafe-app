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
            ZStack(alignment: .bottom) {
                Color.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        pageHeader
                        loyaltyCard
                            .padding(.horizontal, 22)
                            .padding(.top, 12)
                        actionCards
                            .padding(.horizontal, 22)
                            .padding(.top, 14)
                        pointsHistory
                            .padding(.horizontal, 22)
                            .padding(.top, 22)
                        settingsSection
                            .padding(.horizontal, 22)
                            .padding(.top, 22)
                        signOutButton
                            .padding(.horizontal, 22)
                            .padding(.top, 14)
                        Spacer().frame(height: 110)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
            .task { await viewModel.load(customerId: currentUser.id) }
            .navigationDestination(isPresented: $showRewards) {
                RewardsView(viewModel: viewModel, currentUser: currentUser)
            }
            .navigationDestination(isPresented: $showBarcode) {
                if let account = viewModel.account {
                    BarcodeView(membershipBarcode: account.membershipBarcode)
                }
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
        }
    }

    // MARK: - Page header

    private var pageHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Member since '24")
                    .font(.mono(10.5))
                    .foregroundStyle(Color.bark)
                    .tracking(1.6)
                    .textCase(.uppercase)
                Text("Profile")
                    .font(.serif(32))
                    .foregroundStyle(Color.espresso)
            }
            Spacer()
            Circle()
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 0.5))
                .overlay(
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color.bark)
                )
        }
        .padding(.horizontal, 22)
        .padding(.top, 68)
        .padding(.bottom, 8)
    }

    // MARK: - Loyalty dashboard card

    private var loyaltyCard: some View {
        ZStack(alignment: .topTrailing) {
            // Decorative rings
            Circle()
                .stroke(Color.cream.opacity(0.10), lineWidth: 1)
                .frame(width: 200, height: 200)
                .offset(x: 60, y: -60)
            Circle()
                .stroke(Color.cream.opacity(0.07), lineWidth: 1)
                .frame(width: 240, height: 240)
                .offset(x: 90, y: -90)

            VStack(alignment: .leading, spacing: 0) {
                // Avatar + name
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.terra)
                        .frame(width: 52, height: 52)
                        .overlay(Circle().strokeBorder(Color.cream.opacity(0.2), lineWidth: 1))
                        .overlay(
                            Text(initials)
                                .font(.serif(20))
                                .foregroundStyle(Color.cream)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentUser.displayName)
                            .font(.sans(16, weight: .semibold))
                            .foregroundStyle(Color.cream)
                        Text(currentUser.email)
                            .font(.sans(12.5))
                            .foregroundStyle(Color.cream.opacity(0.6))
                    }
                }

                // Points balance
                VStack(alignment: .leading, spacing: 4) {
                    Text("Balance")
                        .font(.mono(10.5))
                        .foregroundStyle(Color.cream.opacity(0.55))
                        .tracking(1.4)
                        .textCase(.uppercase)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(viewModel.account?.totalPoints ?? 0)")
                            .font(.serif(52))
                            .foregroundStyle(Color.amber)
                            .contentTransition(.numericText())
                        Text("pts")
                            .font(.sans(14))
                            .foregroundStyle(Color.cream.opacity(0.7))
                    }
                }
                .padding(.top, 18)

                // Progress to next free coffee
                loyaltyProgress
                    .padding(.top, 16)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipped()
        .background(
            LinearGradient(
                colors: [Color.espresso, Color.bark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.espresso.opacity(0.28), radius: 15, y: 14)
    }

    private var loyaltyProgress: some View {
        let ordersToNextCoffee = 10
        let currentOrders = (viewModel.account?.totalPoints ?? 0) / 10 // proxy
        let progress = min(Double(currentOrders % ordersToNextCoffee) / Double(ordersToNextCoffee), 1.0)

        return VStack(spacing: 6) {
            HStack {
                Text("Next free coffee")
                    .font(.sans(12))
                    .foregroundStyle(Color.cream.opacity(0.75))
                Spacer()
                Text("\(currentOrders % ordersToNextCoffee) / \(ordersToNextCoffee)")
                    .font(.mono(11.5, weight: .semibold))
                    .foregroundStyle(Color.cream)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 100, style: .continuous)
                        .fill(Color.cream.opacity(0.12))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 100, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.terra, Color.amber],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * progress), height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Action cards

    private var actionCards: some View {
        HStack(spacing: 10) {
            actionCard(
                icon: "creditcard",
                label: "Membership",
                meta: "Black tier",
                accent: false,
                action: { showBarcode = true }
            )
            actionCard(
                icon: "gift",
                label: "My rewards",
                meta: rewardsCountText,
                accent: true,
                action: { showRewards = true }
            )
        }
    }

    private var rewardsCountText: String {
        let active = viewModel.rewards.filter { $0.isActive }.count
        return active > 0 ? "\(active) active" : "No rewards yet"
    }

    private func actionCard(icon: String, label: String, meta: String, accent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accent ? Color.amberSoft : Color.cream)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(accent ? Color(hex: "#7A5520") : Color.espresso)
                        )
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.sans(14, weight: .semibold))
                        .foregroundStyle(Color.espresso)
                    Text(meta)
                        .font(.sans(12))
                        .foregroundStyle(Color.bark)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Points history (timeline)

    private var pointsHistory: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Points history")
                .font(.sans(12, weight: .semibold))
                .foregroundStyle(Color.bark)
                .tracking(1.2)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                if viewModel.transactions.isEmpty {
                    Text("No transactions yet.")
                        .font(.sans(14))
                        .foregroundStyle(Color.inkMuted)
                        .padding(.vertical, 16)
                } else {
                    ForEach(Array(viewModel.transactions.enumerated()), id: \.element.id) { i, tx in
                        timelineRow(tx: tx, isLast: i == viewModel.transactions.count - 1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .cardStyle()
        }
    }

    private func timelineRow(tx: PointTransaction, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Dot + line
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.cafeGreen)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.cafeGreen.opacity(0.18), lineWidth: 3))
                    .padding(.top, 4)
                if !isLast {
                    Rectangle()
                        .fill(Color.cardBorder)
                        .frame(width: 1.5)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 14)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Order #\(tx.orderId.prefix(8).uppercased())")
                            .font(.serif(15))
                            .foregroundStyle(Color.espresso)
                        ForEach(tx.itemBreakdown, id: \.itemId) { item in
                            Text("  \(item.itemName): +\(item.pointsEarned) pts")
                                .font(.sans(12))
                                .foregroundStyle(Color.bark)
                        }
                        Text(tx.createdAt, style: .relative)
                            .font(.mono(10.5))
                            .foregroundStyle(Color.inkMuted)
                            .tracking(0.4)
                            .textCase(.uppercase)
                            .padding(.top, 4)
                    }
                    Spacer()
                    Text("+\(tx.totalPointsEarned) pts")
                        .font(.mono(11.5, weight: .bold))
                        .foregroundStyle(Color(hex: "#3F6240"))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Color.cafeGreen.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            Button { showNotificationSettings = true } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.cream)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "bell")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(Color.espresso)
                        )
                    Text("Notification Preferences")
                        .font(.sans(17))
                        .foregroundStyle(Color.espresso)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }

    // MARK: - Sign out

    private var signOutButton: some View {
        Button(role: .destructive) {
            Task { await onSignOut() }
        } label: {
            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.sans(16, weight: .semibold))
                .foregroundStyle(Color.cafeRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cafeRedSoft)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.cafeRed.opacity(0.2), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        currentUser.displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }
}
