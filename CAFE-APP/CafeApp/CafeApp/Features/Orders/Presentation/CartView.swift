import SwiftUI

struct CartView: View {
    @State var orderViewModel: OrderViewModel
    @State private var showCheckout = false

    var body: some View {
        NavigationStack {
            Group {
                if orderViewModel.cart.isEmpty {
                    ContentUnavailableView(
                        "Your cart is empty",
                        systemImage: "cart",
                        description: Text("Browse the menu to add items.")
                    )
                } else {
                    List {
                        ForEach(Array(orderViewModel.cart.enumerated()), id: \.offset) { index, item in
                            CartItemRow(item: item, index: index, orderViewModel: orderViewModel)
                        }
                        .onDelete { orderViewModel.removeFromCart(at: $0) }

                        Section {
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text(orderViewModel.cartTotal, format: .currency(code: "USD"))
                                    .font(.headline)
                            }
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .foregroundStyle(.yellow)
                                Text("\(orderViewModel.cartPoints) pts will be earned")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section {
                            Button(action: { showCheckout = true }) {
                                Text("Checkout")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!orderViewModel.isOrderingAllowed || orderViewModel.cart.isEmpty)
                        }
                    }
                }
            }
            .navigationTitle("Cart")
            .sheet(isPresented: $showCheckout) {
                CheckoutView(orderViewModel: orderViewModel)
            }
            .task { orderViewModel.loadCafeConfig() }
        }
    }
}

struct CartItemRow: View {
    let item: OrderItem
    let index: Int
    @State var orderViewModel: OrderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.name).font(.headline)
                Spacer()
                Text(item.price, format: .currency(code: "USD"))
                    .foregroundStyle(.secondary)
            }
            if let size = item.size {
                Text(size).font(.caption).foregroundStyle(.secondary)
            }
            if let inst = item.specialInstructions {
                Text(inst).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
