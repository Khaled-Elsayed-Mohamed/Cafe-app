import Foundation

struct OrderItem {
    let menuItemId: String
    let name: String
    let size: String?
    let specialInstructions: String?
    let pointValue: Int
    let price: Double
    var isCheckedOff: Bool
}
