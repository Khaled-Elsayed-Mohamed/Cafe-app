import SwiftUI

struct MenuItemFormView: View {
    @Environment(\.dismiss) private var dismiss

    let existing: MenuItem?
    let onSave: (MenuItem) async -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var inStorePrice = ""
    @State private var appPrice = ""
    @State private var pointValue = ""
    @State private var category: MenuCategory = .coffee
    @State private var isAvailable = true
    @State private var isAppOnly = false
    @State private var allergens = ""
    @State private var sizeDrafts: [SizeDraft] = []
    @State private var isSaving = false

    var title: String { existing == nil ? "Add Item" : "Edit Item" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    Picker("Category", selection: $category) {
                        ForEach(MenuCategory.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                }

                Section("Pricing") {
                    LabeledContent("Base Price") {
                        TextField("e.g. 5.50", text: $inStorePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("App Price") {
                        TextField("optional", text: $appPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Loyalty Points") {
                        TextField("e.g. 5", text: $pointValue)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    ForEach($sizeDrafts) { $draft in
                        HStack(spacing: 12) {
                            TextField("Size name", text: $draft.name)
                                .frame(minWidth: 80)
                            Divider()
                            Text("$").foregroundStyle(.secondary)
                            TextField("Price", text: $draft.price)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .onDelete { sizeDrafts.remove(atOffsets: $0) }

                    Button(action: addSize) {
                        Label("Add Size", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Sizes")
                } footer: {
                    Text("If no sizes are added, the base price is used.")
                }

                Section("Options") {
                    Toggle("Available", isOn: $isAvailable)
                    Toggle("App Only", isOn: $isAppOnly)
                    TextField("Allergens (comma-separated)", text: $allergens)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { submit() }
                        .disabled(name.isEmpty || inStorePrice.isEmpty || isSaving)
                }
            }
        }
        .onAppear { prefill() }
    }

    private func prefill() {
        guard let item = existing else { return }
        name = item.name
        description = item.description
        inStorePrice = String(item.inStorePrice)
        appPrice = item.appPrice.map { String($0) } ?? ""
        pointValue = String(item.pointValue)
        category = item.category
        isAvailable = item.isAvailable
        isAppOnly = item.isAppOnly
        allergens = item.allergens.joined(separator: ", ")
        sizeDrafts = item.sizes.map { SizeDraft(name: $0.name, price: String($0.price)) }
    }

    private func addSize() {
        let defaultNames = ["Small", "Medium", "Large", "Regular", "Extra Large"]
        let used = sizeDrafts.map(\.name)
        let next = defaultNames.first { !used.contains($0) } ?? "Size \(sizeDrafts.count + 1)"
        sizeDrafts.append(SizeDraft(name: next, price: inStorePrice))
    }

    private func submit() {
        guard let price = Double(inStorePrice) else { return }
        let parsedSizes = sizeDrafts.compactMap { draft -> ItemSize? in
            guard !draft.name.isEmpty, let p = Double(draft.price) else { return nil }
            return ItemSize(name: draft.name, price: p)
        }
        let item = MenuItem(
            id: existing?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            inStorePrice: price,
            appPrice: Double(appPrice),
            isAppOnly: isAppOnly,
            allergens: allergens.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            pointValue: Int(pointValue) ?? 0,
            category: category,
            isAvailable: isAvailable,
            sizes: parsedSizes
        )
        isSaving = true
        Task {
            await onSave(item)
            dismiss()
        }
    }
}

struct SizeDraft: Identifiable {
    let id = UUID()
    var name: String
    var price: String
}
