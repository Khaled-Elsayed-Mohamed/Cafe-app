import SwiftUI

struct CheckoutView: View {
    @State var orderViewModel: OrderViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var requestedTime = Date().addingTimeInterval(30 * 60)
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Order Summary") {
                    ForEach(Array(orderViewModel.cart.enumerated()), id: \.offset) { _, item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name).font(.subheadline)
                                if let size = item.size {
                                    Text(size).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(item.price, format: .currency(code: "USD"))
                                .font(.subheadline)
                        }
                    }
                    HStack {
                        Text("Total").fontWeight(.semibold)
                        Spacer()
                        Text(orderViewModel.cartTotal, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                    }
                }

                Section("Pick-up Time") {
                    if let config = orderViewModel.cafeConfig {
                        DatePicker(
                            "Ready by",
                            selection: $requestedTime,
                            in: pickupRange(config: config),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } else {
                        ProgressView()
                    }
                }

                if let error = orderViewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                Section {
                    Button(action: {
                        Task {
                            await orderViewModel.placeOrder(requestedTime: requestedTime)
                            if orderViewModel.activeOrder != nil {
                                showConfirmation = true
                            }
                        }
                    }) {
                        if orderViewModel.isLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Label("Pay \(orderViewModel.cartTotal.formatted(.currency(code: "USD")))",
                                  systemImage: "creditcard")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(orderViewModel.isLoading)
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showConfirmation) {
                if let order = orderViewModel.activeOrder {
                    OrderConfirmationView(order: order, orderViewModel: orderViewModel)
                }
            }
        }
        .task { orderViewModel.loadCafeConfig() }
    }

    private func pickupRange(config: CafeConfig) -> ClosedRange<Date> {
        let earliest = Date().addingTimeInterval(15 * 60)
        var cal = Calendar.current
        cal.timeZone = config.timezone
        let parts = config.closeTime.split(separator: ":").compactMap { Int($0) }
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = parts.first ?? 20
        comps.minute = (parts.count > 1 ? parts[1] : 0) - config.orderCutoffMinutes
        let latest = cal.date(from: comps) ?? Date().addingTimeInterval(3 * 3600)
        return earliest...max(earliest, latest)
    }
}
