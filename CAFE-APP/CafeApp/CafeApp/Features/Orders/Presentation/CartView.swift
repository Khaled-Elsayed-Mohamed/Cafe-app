import SwiftUI

struct CartView: View {
    @State var orderViewModel: OrderViewModel
    @State private var showCheckout = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.paper.ignoresSafeArea()

                if orderViewModel.cart.isEmpty {
                    emptyState
                } else {
                    cartContent
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCheckout) {
                CheckoutView(orderViewModel: orderViewModel)
            }
            .task { orderViewModel.loadCafeConfig() }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            // Page header
            cartHeader
                .frame(maxHeight: .infinity, alignment: .top)

            Spacer()
            VStack(spacing: 14) {
                Image(systemName: "cart")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(Color.oat)
                Text("Your cart is empty")
                    .font(.serif(24))
                    .foregroundStyle(Color.espresso)
                Text("Browse the menu to add items.")
                    .font(.sans(14))
                    .foregroundStyle(Color.bark)
            }
            Spacer()
        }
    }

    // MARK: - Cart content

    private var cartContent: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    cartHeader

                    // Pickup card
                    pickupCard
                        .padding(.horizontal, 22)
                        .padding(.top, 12)

                    // Items
                    VStack(spacing: 10) {
                        ForEach(Array(orderViewModel.cart.enumerated()), id: \.offset) { index, item in
                            CartItemRow(item: item, index: index, orderViewModel: orderViewModel)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 14)

                    // Loyalty row
                    loyaltyRow
                        .padding(.horizontal, 22)
                        .padding(.top, 14)

                    // Totals
                    totalsSection
                        .padding(.horizontal, 22)
                        .padding(.top, 18)

                    Spacer().frame(height: 160)
                }
            }
            .scrollIndicators(.hidden)

            checkoutBar
        }
    }

    // MARK: - Header

    private var cartHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your order")
                    .font(.mono(10.5))
                    .foregroundStyle(Color.bark)
                    .tracking(1.6)
                    .textCase(.uppercase)
                Text("Cart")
                    .font(.serif(32))
                    .foregroundStyle(Color.espresso)
            }
            Spacer()
            Label("Pickup · 7 min", systemImage: "clock")
                .font(.sans(12.5, weight: .semibold))
                .foregroundStyle(Color.espresso)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 100, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 100, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 0.5))
        }
        .padding(.horizontal, 22)
        .padding(.top, 68)
        .padding(.bottom, 8)
    }

    // MARK: - Pickup card

    private var pickupCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.cream)
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "house")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Color.espresso)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Macchiato & Co Campbelltown")
                    .font(.sans(14, weight: .semibold))
                    .foregroundStyle(Color.espresso)
                Text("224 Queen St · Pickup in-store")
                    .font(.sans(12))
                    .foregroundStyle(Color.bark)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.inkMuted)
        }
        .padding(14)
        .cardStyle()
    }

    // MARK: - Loyalty row

    private var loyaltyRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.amber)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.paper)
                )
                .shadow(color: Color.amber.opacity(0.4), radius: 6, y: 4)

            VStack(alignment: .leading, spacing: 1) {
                Text("You'll earn \(orderViewModel.cartPoints) pts on this order")
                    .font(.sans(13.5, weight: .semibold))
                    .foregroundStyle(Color(hex: "#5A3D14"))
                Text("Keep ordering to reach your next free coffee")
                    .font(.sans(11.5))
                    .foregroundStyle(Color(hex: "#7A5520"))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.amberSoft, Color.cream],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color(hex: "#B07C30").opacity(0.28), lineWidth: 0.5))
    }

    // MARK: - Totals

    private var totalsSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Subtotal")
                    .font(.sans(13.5))
                    .foregroundStyle(Color.bark)
                Spacer()
                Text(orderViewModel.cartTotal, format: .currency(code: "AUD"))
                    .font(.mono(13.5))
                    .foregroundStyle(Color.bark)
            }
            Divider()
                .background(Color.cardBorder)
                .padding(.vertical, 6)
            HStack(alignment: .bottom) {
                Text("Total")
                    .font(.serif(19))
                    .foregroundStyle(Color.espresso)
                Spacer()
                Text(orderViewModel.cartTotal, format: .currency(code: "AUD"))
                    .font(.serif(26))
                    .foregroundStyle(Color.espresso)
                    .contentTransition(.numericText())
            }
        }
    }

    // MARK: - Checkout bar

    private var checkoutBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.paper.opacity(0), Color.paper.opacity(0.95), Color.paper],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.35)
            )
            .frame(height: 28)

            Button {
                showCheckout = true
            } label: {
                HStack {
                    Image(systemName: "lock")
                        .font(.system(size: 14, weight: .medium))
                    Text("Checkout securely")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .buttonStyle(CTAButtonStyle())
            .disabled(!orderViewModel.isOrderingAllowed || orderViewModel.cart.isEmpty)
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
            .background(Color.paper)
        }
    }
}

// MARK: - CartItemRow

struct CartItemRow: View {
    let item: OrderItem
    let index: Int
    @State var orderViewModel: OrderViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#D9C9AC"), Color(hex: "#C8B38E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.serif(17))
                    .foregroundStyle(Color.espresso)
                    .lineLimit(1)
                Group {
                    if let size = item.size {
                        Text(size)
                    }
                    if let inst = item.specialInstructions {
                        Text(inst)
                    }
                }
                .font(.sans(12))
                .foregroundStyle(Color.bark)
                .lineLimit(1)

                Text(item.lineTotal, format: .currency(code: "AUD"))
                    .font(.serif(14))
                    .foregroundStyle(Color.espresso)
                    .padding(.top, 2)
            }

            Spacer()

            // Quantity stepper pill
            HStack(spacing: 0) {
                Button {
                    orderViewModel.updateQuantity(at: index, quantity: item.quantity - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.bark)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Text("\(item.quantity)")
                    .font(.serif(15))
                    .foregroundStyle(Color.espresso)
                    .frame(minWidth: 22)
                    .contentTransition(.numericText())

                Button {
                    orderViewModel.updateQuantity(at: index, quantity: item.quantity + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.cream)
                        .frame(width: 28, height: 28)
                        .background(Color.espresso)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(3)
            .background(Color.cream)
            .clipShape(RoundedRectangle(cornerRadius: 100, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 100, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 0.5))
        }
        .padding(12)
        .cardStyle()
    }
}
