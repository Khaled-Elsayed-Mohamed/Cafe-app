import SwiftUI

struct OwnerMenuView: View {
    @State var viewModel: OwnerMenuViewModel
    @State private var showAddForm = false
    @State private var editingItem: MenuItem?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.items.isEmpty {
                    ContentUnavailableView(
                        "No Menu Items",
                        systemImage: "fork.knife",
                        description: Text("Tap + to add your first item.")
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Menu")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddForm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddForm) {
                MenuItemFormView(existing: nil) { item in
                    await viewModel.save(item)
                }
            }
            .sheet(item: $editingItem) { item in
                MenuItemFormView(existing: item) { updated in
                    await viewModel.save(updated)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task { await viewModel.load() }
    }

    private var list: some View {
        List {
            ForEach(MenuCategory.allCases, id: \.self) { cat in
                let catItems = viewModel.items.filter { $0.category == cat }
                if !catItems.isEmpty {
                    Section(cat.rawValue) {
                        ForEach(catItems) { item in
                            OwnerMenuRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture { editingItem = item }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        Task { await viewModel.toggleAvailability(item) }
                                    } label: {
                                        Label(
                                            item.isAvailable ? "Hide" : "Show",
                                            systemImage: item.isAvailable ? "eye.slash" : "eye"
                                        )
                                    }
                                    .tint(item.isAvailable ? .orange : .green)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.delete(item) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
}

private struct OwnerMenuRow: View {
    let item: MenuItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline.bold())
                Text(item.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.inStorePrice, format: .currency(code: "AUD"))
                    .font(.subheadline)
                if !item.isAvailable {
                    Text("Hidden")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }
        }
        .opacity(item.isAvailable ? 1 : 0.5)
    }
}
