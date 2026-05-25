import SwiftUI

struct OrderTrackingView: View {
    let order: Order
    @State var orderViewModel: OrderViewModel

    private var displayOrder: Order {
        orderViewModel.activeOrder ?? order
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statusHeader
                readyTimeSection
                statusTimeline
                if displayOrder.status == .expired {
                    expiredNotice
                }
            }
            .padding()
        }
        .navigationTitle("Track Order")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            orderViewModel.observeOrder(id: order.id)
        }
    }

    private var statusHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 48))
                .foregroundStyle(statusColor)
            Text(statusLabel)
                .font(.title2.bold())
            Text("Order #\(order.id.prefix(8).uppercased())")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var readyTimeSection: some View {
        VStack(spacing: 4) {
            Text("Pick-up time")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(displayOrder.requestedReadyTime, style: .time)
                .font(.title3.bold())
            if displayOrder.status == .ready {
                Text(displayOrder.requestedReadyTime, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status Timeline").font(.headline)
            ForEach(OrderStatus.allCases, id: \.self) { step in
                HStack(spacing: 12) {
                    Image(systemName: isCompleted(step) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCompleted(step) ? .green : .secondary)
                    Text(step.displayName)
                        .foregroundStyle(isCompleted(step) ? .primary : .secondary)
                    Spacer()
                    if let ts = timestamp(for: step) {
                        Text(ts, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var expiredNotice: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("This order expired and was not collected.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemOrange).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private var statusIcon: String {
        switch displayOrder.status {
        case .pending: "clock"
        case .accepted: "person.fill.checkmark"
        case .inProcess: "gearshape.fill"
        case .ready: "bag.fill.badge.plus"
        case .completed: "checkmark.seal.fill"
        case .expired: "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch displayOrder.status {
        case .pending: .orange
        case .accepted: .blue
        case .inProcess: .blue
        case .ready: .green
        case .completed: .green
        case .expired: .red
        }
    }

    private var statusLabel: String {
        switch displayOrder.status {
        case .pending: "Waiting for café"
        case .accepted: "Order accepted"
        case .inProcess: "Being prepared"
        case .ready: "Ready for pickup!"
        case .completed: "Collected"
        case .expired: "Order expired"
        }
    }

    private func isCompleted(_ step: OrderStatus) -> Bool {
        let order_steps: [OrderStatus] = [.pending, .accepted, .inProcess, .ready, .completed]
        let current = order_steps.firstIndex(of: displayOrder.status) ?? 0
        let stepIdx = order_steps.firstIndex(of: step) ?? 0
        return stepIdx <= current || displayOrder.status == .completed
    }

    private func timestamp(for step: OrderStatus) -> Date? {
        switch step {
        case .pending: displayOrder.statusTimestamps.pending
        case .accepted: displayOrder.statusTimestamps.accepted
        case .inProcess: displayOrder.statusTimestamps.inProcess
        case .ready: displayOrder.statusTimestamps.ready
        case .completed: displayOrder.statusTimestamps.completed
        case .expired: displayOrder.statusTimestamps.expired
        }
    }
}

extension OrderStatus: CaseIterable {
    static var allCases: [OrderStatus] {
        [.pending, .accepted, .inProcess, .ready, .completed]
    }

    var displayName: String {
        switch self {
        case .pending: "Order placed"
        case .accepted: "Accepted by café"
        case .inProcess: "Being prepared"
        case .ready: "Ready for pickup"
        case .completed: "Collected"
        case .expired: "Expired"
        }
    }
}
