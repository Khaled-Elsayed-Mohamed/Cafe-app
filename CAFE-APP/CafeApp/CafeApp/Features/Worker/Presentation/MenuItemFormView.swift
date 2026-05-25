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
                    TextField("In-Store Price", text: $inStorePrice)
                        .keyboardType(.decimalPad)
                    TextField("App Price (optional)", text: $appPrice)
                        .keyboardType(.decimalPad)
                    TextField("Loyalty Points", text: $pointValue)
                        .keyboardType(.numberPad)
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
    }

    private func submit() {
        guard let price = Double(inStorePrice) else { return }
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
            isAvailable: isAvailable
        )
        isSaving = true
        Task {
            await onSave(item)
            dismiss()
        }
    }
}
