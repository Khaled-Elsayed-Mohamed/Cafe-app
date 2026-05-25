import SwiftUI

struct RewardsView: View {
    @State var viewModel: LoyaltyViewModel
    let currentUser: AuthUser

    private var activeRewards: [Reward] { viewModel.rewards.filter { $0.isActive } }
    private var redeemedRewards: [Reward] { viewModel.rewards.filter { !$0.isActive } }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    pageHeader
                    rewardsList
                    redeemedList
                    Spacer().frame(height: 110)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
    }

    // MARK: - Header

    private var pageHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.account?.totalPoints ?? 0) pts available")
                    .font(.mono(10.5))
                    .foregroundStyle(Color.bark)
                    .tracking(1.6)
                    .textCase(.uppercase)
                Text("My rewards")
                    .font(.serif(32))
                    .foregroundStyle(Color.espresso)
            }
            Spacer()
            if !activeRewards.isEmpty {
                Text("\(activeRewards.count) ACTIVE")
                    .font(.sans(11.5, weight: .bold))
                    .foregroundStyle(Color(hex: "#5A3D14"))
                    .tracking(0.3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.amberSoft)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color(hex: "#B07C30").opacity(0.35), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: - Active rewards

    @ViewBuilder
    private var rewardsList: some View {
        if activeRewards.isEmpty {
            emptyRewards
        } else {
            VStack(spacing: 12) {
                ForEach(activeRewards) { reward in
                    ActiveRewardCard(reward: reward) {
                        Task {
                            await viewModel.redeemReward(id: reward.id, customerId: currentUser.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
    }

    private var emptyRewards: some View {
        VStack(spacing: 14) {
            Image(systemName: "gift")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(Color.oat)
            Text("No Rewards Yet")
                .font(.serif(22))
                .foregroundStyle(Color.espresso)
            Text("Complete your 10th order\nto earn a free coffee!")
                .font(.sans(14))
                .foregroundStyle(Color.bark)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Redeemed rewards

    @ViewBuilder
    private var redeemedList: some View {
        if !redeemedRewards.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recently redeemed")
                    .font(.sans(12, weight: .semibold))
                    .foregroundStyle(Color.bark)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .padding(.horizontal, 22)

                VStack(spacing: 8) {
                    ForEach(redeemedRewards) { reward in
                        RedeemedRewardRow(reward: reward)
                    }
                }
                .padding(.horizontal, 22)
            }
        }
    }
}

// MARK: - ActiveRewardCard

private struct ActiveRewardCard: View {
    let reward: Reward
    let onRedeem: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Illustration area
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [Color(hex: "#EDE2CC"), Color(hex: "#DECDAF")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 130)

                // Cost badge
                Text(costLabel)
                    .font(.mono(10, weight: .bold))
                    .foregroundStyle(Color.espresso)
                    .tracking(0.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.paper.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 100, style: .continuous))
                    .padding(12)

                // Placeholder label
                Text("reward art")
                    .font(.mono(9))
                    .foregroundStyle(Color.espresso.opacity(0.5))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.paper.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(8)
            }

            // Content row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rewardTitle)
                        .font(.serif(19))
                        .foregroundStyle(Color.espresso)
                    Text("Expires \(reward.expiryDate, style: .date)")
                        .font(.sans(12))
                        .foregroundStyle(Color.bark)
                }
                Spacer()
                Button(action: onRedeem) {
                    Text("Redeem")
                        .font(.sans(13, weight: .bold))
                        .foregroundStyle(Color.paper)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.amber)
                        .clipShape(Capsule())
                        .shadow(color: Color.amber.opacity(0.45), radius: 8, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(reward.redemptionStatus != .unredeemed)
            }
            .padding(14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.cardBorderSoft, lineWidth: 0.5))
        .shadow(color: Color.espresso.opacity(0.08), radius: 12, y: 8)
    }

    private var rewardTitle: String {
        switch reward.type {
        case .freeCoffee: return "Free Coffee"
        }
    }

    private var costLabel: String {
        "\(Int(reward.monetaryValue)) pts"
    }
}

// MARK: - RedeemedRewardRow

private struct RedeemedRewardRow: View {
    let reward: Reward

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#8E6A4F"), Color(hex: "#6B4A33")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 1) {
                Text(rewardTitle)
                    .font(.serif(15))
                    .foregroundStyle(Color.bark)
                Text(reward.expiryDate, style: .date)
                    .font(.sans(11.5))
                    .foregroundStyle(Color.inkMuted)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                Text("Used")
                    .font(.mono(10.5, weight: .bold))
                    .tracking(0.4)
                    .textCase(.uppercase)
            }
            .foregroundStyle(Color.inkMuted)
        }
        .padding(10)
        .background(Color.espresso.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .grayscale(0.7)
        .opacity(0.85)
    }

    private var rewardTitle: String {
        switch reward.type {
        case .freeCoffee: return "Free Coffee"
        }
    }
}
