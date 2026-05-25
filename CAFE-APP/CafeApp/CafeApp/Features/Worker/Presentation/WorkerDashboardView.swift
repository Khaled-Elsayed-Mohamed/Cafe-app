import SwiftUI

struct WorkerDashboardView: View {
    @State var viewModel: WorkerOrderViewModel
    @State private var selectedOrder: Order?
    @State private var showMemberLookup = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.activeOrders.isEmpty {
                    ContentUnavailableView(
                        "No Active Orders",
                        systemImage: "tray",
                        description: Text("New orders will appear here in real-time.")
                    )
                } else {
                    List(viewModel.activeOrders) { order in
                        NavigationLink {
                            WorkerOrderDetailView(order: order, viewModel: viewModel)
                        } label: {
                            OrderQueueRow(order: order)
                        }
                    }
                }
            }
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showMemberLookup = true }) {
                        Label("Scan Member", systemImage: "qrcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showMemberLookup) {
                MemberLookupView()
            }
        }
        .task { viewModel.observeOrders() }
    }
}

struct OrderQueueRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("#\(order.id.prefix(8).uppercased())")
                    .font(.headline)
                Spacer()
                StatusBadge(status: order.status)
            }
            Text(order.customerName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text("\(order.items.count) item(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(order.requestedReadyTime, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: OrderStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    var statusColor: Color {
        switch status {
        case .pending: .orange
        case .accepted: .blue
        case .inProcess: .blue
        case .ready: .green
        case .completed: .green
        case .expired: .red
        }
    }
}

struct MemberLookupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("QR Scanner — Phase 6")
                .foregroundStyle(.secondary)
                .navigationTitle("Scan Member")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}
