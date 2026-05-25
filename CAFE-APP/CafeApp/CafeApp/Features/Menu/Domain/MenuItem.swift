import Foundation

struct ItemSize: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let price: Double
}

struct MenuItem: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let inStorePrice: Double
    let appPrice: Double?
    let isAppOnly: Bool
    let allergens: [String]
    let pointValue: Int
    let category: MenuCategory
    let isAvailable: Bool
    let sizes: [ItemSize]
}

enum MenuCategory: String, CaseIterable, Codable {
    case coffee  = "Coffee"
    case food    = "Food"
    case drinks  = "Drinks"
    case pastry  = "Pastry"
}

extension MenuItem {
    var effectiveAppPrice: Double { appPrice ?? inStorePrice }
}
