import Foundation
import Observation

@Observable
final class MenuViewModel {
    var items: [MenuItem] = []
    var isOffline = false
    var isLoading = false
    var searchText = ""
    var selectedCategory: MenuCategory?
    var cafeConfig: CafeConfig?
    var errorMessage: String?

    private let menuRepository: any MenuRepository
    private let networkMonitor: any NetworkMonitorRepository
    private let cafeConfigRepository: any CafeConfigRepository
    private let fetchMenuUseCase: FetchMenuUseCase

    init(
        menuRepository: any MenuRepository,
        networkMonitor: any NetworkMonitorRepository,
        cafeConfigRepository: any CafeConfigRepository
    ) {
        self.menuRepository = menuRepository
        self.networkMonitor = networkMonitor
        self.cafeConfigRepository = cafeConfigRepository
        self.fetchMenuUseCase = FetchMenuUseCase(repository: menuRepository)
    }

    var filteredItems: [MenuItem] {
        var result = items
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.description.lowercased().contains(query)
            }
        }
        return result
    }

    var isOrderingAllowed: Bool {
        guard let config = cafeConfig else { return false }
        return Date().isWithinOrderingWindow(config: config)
    }

    func loadMenu() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await fetchMenuUseCase.execute()
        } catch {
            errorMessage = "Menu unavailable. Showing cached menu."
            items = menuRepository.fetchCachedMenu()
        }
        isLoading = false
    }

    func observeConnectivity() {
        Task {
            for await connected in networkMonitor.observeConnectivity() {
                isOffline = !connected
            }
        }
    }

    func observeMenuUpdates() {
        Task {
            for await updated in menuRepository.observeMenuUpdates() {
                items = updated
            }
        }
    }

    func observeCafeConfig() {
        Task {
            cafeConfig = try? await cafeConfigRepository.fetchConfig()
            for await config in cafeConfigRepository.observeConfig() {
                cafeConfig = config
            }
        }
    }
}
