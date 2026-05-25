import SwiftUI

struct OwnerDashboardView: View {
    let workerOrderViewModel: WorkerOrderViewModel
    let menuRepository: any MenuRepository
    let onSignOut: () async -> Void
    let onSwitchToCustomer: () -> Void

    var body: some View {
        TabView {
            WorkerDashboardView(viewModel: workerOrderViewModel)
                .tabItem { Label("Orders", systemImage: "tray.full") }

            OwnerMenuView(viewModel: OwnerMenuViewModel(repository: menuRepository))
                .tabItem { Label("Menu", systemImage: "fork.knife") }

            ownerSettingsView
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }

    private var ownerSettingsView: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: onSwitchToCustomer) {
                        Label("Switch to Customer View", systemImage: "person.crop.circle")
                    }
                }
                Section {
                    Button(role: .destructive) {
                        Task { await onSignOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
