import Foundation
import Observation

@Observable
final class OwnerMenuViewModel {
    var items: [MenuItem] = []
    var isLoading = false
    var errorMessage: String?

    private let repository: any MenuRepository

    init(repository: any MenuRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await repository.fetchAllMenuItems()
        } catch {
            errorMessage = "Failed to load menu."
        }
        isLoading = false
    }

    func save(_ item: MenuItem) async {
        do {
            try await repository.saveMenuItem(item)
            await load()
        } catch {
            errorMessage = "Failed to save item."
        }
    }

    func delete(_ item: MenuItem) async {
        do {
            try await repository.deleteMenuItem(id: item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete item."
        }
    }

    func toggleAvailability(_ item: MenuItem) async {
        let updated = MenuItem(
            id: item.id,
            name: item.name,
            description: item.description,
            inStorePrice: item.inStorePrice,
            appPrice: item.appPrice,
            isAppOnly: item.isAppOnly,
            allergens: item.allergens,
            pointValue: item.pointValue,
            category: item.category,
            isAvailable: !item.isAvailable
        )
        await save(updated)
    }
}
