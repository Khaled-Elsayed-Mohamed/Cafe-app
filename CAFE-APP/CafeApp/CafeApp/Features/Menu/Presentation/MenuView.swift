import SwiftUI

struct MenuView: View {
    @State var viewModel: MenuViewModel
    @State var orderViewModel: OrderViewModel
    @State private var selectedItem: MenuItem?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                List {
                    if viewModel.isOffline {
                        offlineBanner
                    }
                    if !viewModel.isOrderingAllowed {
                        closedBanner
                    }
                    categoryPicker
                    ForEach(viewModel.filteredItems) { item in
                        NavigationLink {
                            MenuItemDetailView(item: item, orderViewModel: orderViewModel)
                        } label: {
                            MenuItemRow(item: item)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $viewModel.searchText, prompt: "Search menu")
                .refreshable { await viewModel.loadMenu() }
                .navigationTitle("Menu")
            }
        }
        .task {
            await viewModel.loadMenu()
            viewModel.observeConnectivity()
            viewModel.observeMenuUpdates()
            viewModel.observeCafeConfig()
        }
    }

    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("You're offline — showing cached menu")
                .font(.footnote)
        }
        .foregroundStyle(.secondary)
        .listRowBackground(Color(.systemYellow).opacity(0.3))
    }

    private var closedBanner: some View {
        HStack {
            Image(systemName: "clock")
            Text("Café is currently closed for orders")
                .font(.footnote)
        }
        .foregroundStyle(.secondary)
        .listRowBackground(Color(.systemRed).opacity(0.15))
    }

    private var categoryPicker: some View {
        Picker("Category", selection: $viewModel.selectedCategory) {
            Text("All").tag(Optional<MenuCategory>(nil))
            ForEach(MenuCategory.allCases, id: \.self) { cat in
                Text(cat.rawValue).tag(Optional(cat))
            }
        }
        .pickerStyle(.segmented)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .padding(.vertical, 4)
    }
}

struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.name)
                    .font(.headline)
                if item.isAppOnly {
                    Text("App Only")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(.clear)
                        .clipShape(Capsule())
                }
                Spacer()
                Text(item.effectiveAppPrice, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(item.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
