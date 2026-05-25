import SwiftUI

struct RewardsView: View {
    @State var viewModel: LoyaltyViewModel
    let currentUser: AuthUser

    var body: some View {
        List {
            if viewModel.rewards.isEmpty {
                ContentUnavailableView(
                    "No Rewards Yet",
                    systemImage: "gift",
                    description: Text("Complete your 10th order to earn a free coffee!")
                )
            } else {
                ForEach(viewModel.rewards) { reward in
                    RewardRow(reward: reward) {
                        Task {
                            await viewModel.redeemReward(id: reward.id, customerId: currentUser.id)
                        }
                    }
                }
            }
        }
        .navigationTitle("My Rewards")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RewardRow: View {
    let reward: Reward
    let onRedeem: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(rewardTitle, systemImage: "cup.and.saucer.fill")
                    .font(.headline)
                Spacer()
                Text(reward.monetaryValue, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Expires")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(reward.expiryDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                statusBadge
                Spacer()
                if reward.isActive {
                    Button("Redeem", action: onRedeem)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var rewardTitle: String {
        switch reward.type {
        case .freeCoffee: "Free Coffee"
        }
    }

    private var statusBadge: some View {
        let (label, color): (String, Color) = switch reward.redemptionStatus {
        case .unredeemed: ("Active", .green)
        case .pendingRedemption: ("Pending Redemption", .orange)
        case .redeemed: ("Redeemed", .secondary)
        }

        return Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
