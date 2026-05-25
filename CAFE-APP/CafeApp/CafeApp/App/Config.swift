import Foundation

enum Config {
    static let squareApplicationId: String = {
        guard let value = Bundle.main.infoDictionary?["SQUARE_APPLICATION_ID"] as? String,
              !value.isEmpty else {
            fatalError("SQUARE_APPLICATION_ID not set in Info.plist. Add it via Build Settings → User-Defined.")
        }
        return value
    }()
}
