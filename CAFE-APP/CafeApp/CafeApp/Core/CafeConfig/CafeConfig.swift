import Foundation

struct CafeConfig {
    let openTime: String            // "HH:mm"
    let closeTime: String           // "HH:mm"
    let orderCutoffMinutes: Int     // default 15
    let orderTimeoutMinutes: Int    // default 120
    let timezone: TimeZone
}
