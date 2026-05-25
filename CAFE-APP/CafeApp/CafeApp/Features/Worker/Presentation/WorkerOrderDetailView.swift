import SwiftUI

struct WorkerOrderDetailView: View {
    let order: Order
    @State var viewModel: WorkerOrderViewModel
    @State private var showCompleteConfirm = false

    var body: some View {
        Form {
            Section("Customer") {
                LabeledContent("Name", value: order.customerName)
                LabeledContent("Order #", value: "#\(order.id.prefix(8).uppercased())")
                LabeledContent("Ready by", value: order.requestedReadyTime, format: .dateTime.hour().minute())
            }

            Section("Status") {
                StatusBadge(status: order.status)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if order.status == .pending {
                    Button(action: {
                        Task { await viewModel.accept(order: order) }
                    }) {
                        Label("Accept Order", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if order.status == .ready {
                    Button(action: { showCompleteConfirm = true }) {
                        Label("Mark Collected", systemImage: "bag.badge.checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }

            Section("Items") {
                ForEach(Array(order.items.enumerated()), id: \.offset) { index, item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(.headline)
                            if let size = item.size {
                                Text(size).font(.caption).foregroundStyle(.secondary)
                            }
                            if let inst = item.specialInstructions {
                                Text(inst).font(.caption).foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { item.isCheckedOff },
                            set: { _ in
                                Task { await viewModel.checkOff(order: order, itemIndex: index) }
                            }
                        ))
                        .labelsHidden()
                    }
                    .opacity(item.isCheckedOff ? 0.5 : 1.0)
                }
            }
        }
        .navigationTitle("Order Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Mark as Collected?", isPresented: $showCompleteConfirm) {
            Button("Confirm") {
                Task { await viewModel.markCompleted(order: order) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Confirm the customer has picked up their order.")
        }
    }
}
