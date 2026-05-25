import Foundation

struct OrderItem {
    let menuItemId: String
    let name: String
    let size: String?
    let specialInstructions: String?
    let pointValue: Int
    let price: Double        // unit price
    var quantity: Int
    var isCheckedOff: Bool

    var lineTotal: Double { price * Double(quantity) }
    var linePoints: Int { pointValue * quantity }
}
