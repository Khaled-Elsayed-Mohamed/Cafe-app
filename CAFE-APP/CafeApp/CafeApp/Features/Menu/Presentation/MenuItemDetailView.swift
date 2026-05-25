import SwiftUI

struct MenuItemDetailView: View {
    let item: MenuItem
    @State var orderViewModel: OrderViewModel
    @State private var selectedSize: String?
    @State private var specialInstructions = ""
    @State private var addedToCart = false
    @Environment(\.dismiss) private var dismiss

    private let availableSizes = ["Small", "Medium", "Large"]

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.name)
                            .font(.title2.bold())
                        if item.isAppOnly {
                            Text("App Only")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(.clear)
                                .clipShape(Capsule())
                        }
                    }
                    Text(item.effectiveAppPrice, format: .currency(code: "USD"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Description") {
                Text(item.description)
            }

            if !item.allergens.isEmpty {
                Section("Allergens") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(item.allergens, id: \.self) { allergen in
                                Text(allergen.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemOrange).opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            Section {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .foregroundStyle(.yellow)
                    Text("\(item.pointValue) pts per item")
                        .font(.subheadline)
                }
            }

            Section("Size") {
                Picker("Size", selection: $selectedSize) {
                    Text("No preference").tag(Optional<String>(nil))
                    ForEach(availableSizes, id: \.self) { size in
                        Text(size).tag(Optional(size))
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Special Instructions") {
                TextField("e.g. oat milk, no sugar", text: $specialInstructions, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section {
                Button(action: {
                    let orderItem = OrderItem(
                        menuItemId: item.id,
                        name: item.name,
                        size: selectedSize,
                        specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions,
                        pointValue: item.pointValue,
                        price: item.effectiveAppPrice,
                        isCheckedOff: false
                    )
                    orderViewModel.addToCart(orderItem)
                    addedToCart = true
                }) {
                    Label("Add to Order", systemImage: "cart.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Added to Order", isPresented: $addedToCart) {
            Button("Keep Browsing") {}
            Button("View Cart") { dismiss() }
        }
    }
}
