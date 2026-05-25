import SwiftUI

struct MenuItemDetailView: View {
    let item: MenuItem
    @State var orderViewModel: OrderViewModel
    @Binding var selectedTab: Int
    @State private var selectedSize: ItemSize?
    @State private var quantity = 1
    @State private var specialInstructions = ""
    @State private var addedToCart = false
    @Environment(\.dismiss) private var dismiss

    private static let defaultSizeOffsets: [(name: String, label: String, vol: String, offset: Double)] = [
        ("S", "Small",  "6 oz",  0.00),
        ("M", "Reg.",   "8 oz",  0.50),
        ("L", "Large",  "12 oz", 1.00),
    ]

    private var effectiveSizes: [ItemSize] {
        if !item.sizes.isEmpty { return item.sizes }
        if item.category == .coffee || item.category == .drinks {
            return Self.defaultSizeOffsets.map {
                ItemSize(name: $0.name, price: item.effectiveAppPrice + $0.offset)
            }
        }
        return []
    }

    private var showSizePicker: Bool { !effectiveSizes.isEmpty }

    private var displayPrice: Double {
        selectedSize?.price ?? effectiveSizes.first?.price ?? item.effectiveAppPrice
    }

    private var totalPrice: Double { displayPrice * Double(quantity) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    contentCard
                }
                .padding(.bottom, 110)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

            ctaBar
        }
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.espresso)
                    .frame(width: 40, height: 40)
                    .background(Color.paper.opacity(0.85))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
            }
            .padding(.top, 56)
            .padding(.leading, 16)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.amber)
                Text("Earns \(item.pointValue * quantity) pts")
                    .font(.sans(12.5, weight: .semibold))
                    .foregroundStyle(Color.espresso)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.paper.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 100, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
            .padding(.top, 56)
            .padding(.trailing, 16)
        }
        .alert("Added to Order", isPresented: $addedToCart) {
            Button("Keep Browsing") { dismiss() }
            Button("View Cart") { dismiss(); selectedTab = 1 }
        }
        .onAppear {
            if selectedSize == nil { selectedSize = effectiveSizes.first }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack {
            // Placeholder hero (gradient)
            LinearGradient(
                colors: [Color(hex: "#8E6A4F"), Color(hex: "#6B4A33")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 320)
            // Legibility wash
            LinearGradient(
                colors: [Color.espresso.opacity(0.55), Color.espresso.opacity(0)],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.5)
            )
            .frame(height: 320)
            Text("hero · \(item.name.lowercased())")
                .font(.mono(9))
                .foregroundStyle(Color.espresso.opacity(0.5))
                .tracking(0.4)
                .textCase(.uppercase)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.paper.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .frame(height: 320)
    }

    // MARK: - Content card

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title + price
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category.rawValue)
                        .font(.mono(10.5))
                        .foregroundStyle(Color.bark)
                        .tracking(1.6)
                        .textCase(.uppercase)
                    Text(item.name)
                        .font(.serif(32))
                        .foregroundStyle(Color.espresso)
                        .lineLimit(2)
                }
                Spacer()
                Text(displayPrice, format: .currency(code: "AUD"))
                    .font(.serif(26))
                    .foregroundStyle(Color.espresso)
                    .contentTransition(.numericText())
            }
            .padding(.top, 24)

            // Description
            Text(item.description)
                .font(.sans(14))
                .foregroundStyle(Color.bark)
                .lineSpacing(4)
                .padding(.top, 12)

            // Allergens
            if !item.allergens.isEmpty {
                allergenRow
            }

            // Size chips
            if showSizePicker {
                sizeSection
            }

            // Quantity
            quantitySection

            // Special instructions
            instructionsField
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .offset(y: -28)
    }

    // MARK: - Allergens

    private var allergenRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Allergens")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(item.allergens, id: \.self) { allergen in
                        Text(allergen.capitalized)
                            .font(.sans(12))
                            .foregroundStyle(Color(hex: "#7A3A14"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.amberSoft)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.top, 22)
    }

    // MARK: - Size chips

    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Size")
            HStack(spacing: 8) {
                ForEach(effectiveSizes) { size in
                    let isSelected = selectedSize?.id == size.id
                    Button { withAnimation(.spring(duration: 0.22)) { selectedSize = size } } label: {
                        VStack(spacing: 2) {
                            Text(size.name)
                                .font(.sans(13, weight: .semibold))
                            Text(size.price, format: .currency(code: "AUD"))
                                .font(.mono(10))
                                .foregroundStyle(isSelected ? Color.cream.opacity(0.7) : Color.inkMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Color.espresso : Color.white)
                        .foregroundStyle(isSelected ? Color.cream : Color.espresso)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(isSelected ? nil : RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 0.5))
                        .shadow(color: Color.espresso.opacity(isSelected ? 0.22 : 0), radius: 8, y: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 22)
    }

    // MARK: - Quantity

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Quantity")
            HStack(spacing: 0) {
                Button {
                    withAnimation(.spring(duration: 0.18)) { if quantity > 1 { quantity -= 1 } }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(quantity <= 1 ? Color.inkMuted : Color.espresso)
                        .frame(width: 44, height: 44)
                }
                Text("\(quantity)")
                    .font(.serif(18))
                    .foregroundStyle(Color.espresso)
                    .frame(minWidth: 36)
                    .contentTransition(.numericText())
                Button {
                    withAnimation(.spring(duration: 0.18)) { if quantity < 20 { quantity += 1 } }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.espresso)
                        .frame(width: 44, height: 44)
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 100, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 100, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 0.5))
        }
        .padding(.top, 22)
    }

    // MARK: - Special instructions

    private var instructionsField: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Special instructions")
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.cream)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Color.bark)
                    )
                VStack(alignment: .leading, spacing: 6) {
                    TextField("e.g. oat milk, no sugar", text: $specialInstructions, axis: .vertical)
                        .font(.sans(14))
                        .foregroundStyle(Color.espresso)
                        .lineLimit(3, reservesSpace: true)
                    if !specialInstructions.isEmpty {
                        Text("\(specialInstructions.count) / 140")
                            .font(.mono(10))
                            .foregroundStyle(Color.inkMuted)
                            .tracking(0.4)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 0.5))
        }
        .padding(.top, 22)
    }

    // MARK: - CTA bar

    private var ctaBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.paper.opacity(0), Color.paper.opacity(0.95), Color.paper],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.35)
            )
            .frame(height: 28)

            HStack {
                Button(action: addToOrder) {
                    HStack {
                        Text(quantity > 1 ? "Add \(quantity) to Order" : "Add to Order")
                        Spacer()
                        Text(totalPrice, format: .currency(code: "AUD"))
                            .font(.serif(18))
                    }
                }
                .buttonStyle(CTAButtonStyle())
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
            .background(Color.paper)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.sans(12, weight: .semibold))
            .foregroundStyle(Color.bark)
            .tracking(1.2)
            .textCase(.uppercase)
    }

    private func addToOrder() {
        let orderItem = OrderItem(
            menuItemId: item.id,
            name: item.name,
            size: selectedSize?.name,
            specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions,
            pointValue: item.pointValue,
            price: displayPrice,
            quantity: quantity,
            isCheckedOff: false
        )
        orderViewModel.addToCart(orderItem)
        addedToCart = true
    }
}
