import SwiftUI

struct OwnerDashboardView: View {
    let workerOrderViewModel: WorkerOrderViewModel
    let menuRepository: any MenuRepository

    var body: some View {
        TabView {
            WorkerDashboardView(viewModel: workerOrderViewModel)
                .tabItem { Label("Orders", systemImage: "tray.full") }

            OwnerMenuView(viewModel: OwnerMenuViewModel(repository: menuRepository))
                .tabItem { Label("Menu", systemImage: "fork.knife") }
        }
    }
}
