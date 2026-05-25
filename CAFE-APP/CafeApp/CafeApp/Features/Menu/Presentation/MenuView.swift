import SwiftUI

struct MenuView: View {
    @State var viewModel: MenuViewModel
    @State var orderViewModel: OrderViewModel
    @Binding var selectedTab: Int
    @State private var selectedItem: MenuItem?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        heroHeader
                        searchBar
                        categoryPills
                        inlineNotices
                        itemCards
                    }
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadMenu()
            viewModel.observeConnectivity()
            viewModel.observeMenuUpdates()
            viewModel.observeCafeConfig()
        }
    }

    // MARK: - Hero header

    private var heroHeader: some View {
        ZStack(alignment: .topTrailing) {
            // Radial amber glow
            LinearGradient(
                colors: [Color.amberSoft, Color.amberSoft.opacity(0.4), Color.paper],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .frame(height: 180)

            VStack(alignment: .leading, spacing: 6) {
                Text("Good morning · Campbelltown")
                    .font(.mono(10.5))
                    .foregroundStyle(Color.bark)
                    .tracking(1.6)
                    .textCase(.uppercase)

                Text("Macchiato\u{200B}&\u{200B}Co")
                    .font(.serif(38))
                    .foregroundStyle(Color.espresso)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.cafeGreen)
                        .frame(width: 7, height: 7)
                    Text("Open · pickup in ~7 min")
                        .font(.sans(13.5))
                        .foregroundStyle(Color.bark)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 68)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Color.inkMuted)
            TextField("Search coffees, pastries…", text: $viewModel.searchText)
                .font(.sans(15))
                .foregroundStyle(Color.espresso)
            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.inkMuted)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 0.5))
        .shadow(color: Color.espresso.opacity(0.06), radius: 12, y: 6)
        .padding(.horizontal, 22)
        .padding(.top, 18)
    }

    // MARK: - Category pills

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryPill(label: "All", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(MenuCategory.allCases, id: \.self) { cat in
                    categoryPill(label: cat.rawValue, isSelected: viewModel.selectedCategory == cat) {
                        viewModel.selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
        }
    }

    private func categoryPill(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.sans(13.5, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Color.cream : Color.espresso)
                .padding(.vertical, 9)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.espresso : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 100, style: .continuous))
                .overlay(isSelected ? nil : RoundedRectangle(cornerRadius: 100, style: .continuous).strokeBorder(Color.cardBorder, lineWidth: 0.5))
                .shadow(color: Color.espresso.opacity(isSelected ? 0.18 : 0.04), radius: isSelected ? 5 : 0, y: isSelected ? 4 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.22), value: isSelected)
    }

    // MARK: - Inline notices

    @ViewBuilder
    private var inlineNotices: some View {
        if viewModel.isOffline {
            noticeBanner(
                icon: "wifi.slash",
                text: "**You're offline.** Showing the last menu we cached.",
                bg: Color.amberSoft,
                border: Color(hex: "#B07C30").opacity(0.3),
                iconColor: Color(hex: "#7A5520"),
                textColor: Color(hex: "#5A3D14")
            )
        }
        if !viewModel.isOrderingAllowed {
            noticeBanner(
                icon: "moon.fill",
                text: "**We're closed for orders right now.** Check back during opening hours.",
                bg: Color.cafeRedSoft,
                border: Color.cafeRed.opacity(0.3),
                iconColor: Color(hex: "#7A2A24"),
                textColor: Color(hex: "#5A1F1A")
            )
        }
    }

    private func noticeBanner(icon: String, text: String, bg: Color, border: Color, iconColor: Color, textColor: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
                .padding(.top, 1)
            Text(LocalizedStringKey(text))
                .font(.sans(12.5))
                .foregroundStyle(textColor)
                .lineSpacing(2)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(border, lineWidth: 0.5))
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
    }

    // MARK: - Item cards

    private var itemCards: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredItems) { item in
                NavigationLink {
                    MenuItemDetailView(item: item, orderViewModel: orderViewModel, selectedTab: $selectedTab)
                } label: {
                    MenuItemRow(item: item)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 4)
    }
}

// MARK: - MenuItemRow

struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        HStack(spacing: 14) {
            // Image placeholder (espresso-toned rounded square)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(placeholderGradient)
                .frame(width: 72, height: 72)
                .overlay(alignment: .bottomLeading) {
                    Text("photo")
                        .font(.mono(9))
                        .foregroundStyle(Color.espresso.opacity(0.5))
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.paper.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .padding(6)
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.serif(18))
                        .foregroundStyle(Color.espresso)
                        .lineLimit(1)
                    if item.isAppOnly {
                        Text("App Only")
                            .font(.mono(9.5, weight: .bold))
                            .foregroundStyle(Color(hex: "#7A5520"))
                            .tracking(0.4)
                            .textCase(.uppercase)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.amberSoft)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Color(hex: "#B07C30").opacity(0.35), lineWidth: 0.5))
                    }
                }
                Text(item.description)
                    .font(.sans(12.5))
                    .foregroundStyle(Color.bark)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(item.effectiveAppPrice, format: .currency(code: "AUD"))
                    .font(.serif(15, weight: .medium))
                    .foregroundStyle(Color.espresso)
            }

            Spacer(minLength: 0)

            // Add button
            Circle()
                .fill(Color.cream)
                .frame(width: 32, height: 32)
                .overlay(Circle().strokeBorder(Color.cardBorder, lineWidth: 0.5))
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.espresso)
                )
        }
        .padding(12)
        .cardStyle()
    }

    private var placeholderGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#D9C9AC"), Color(hex: "#C8B38E")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
