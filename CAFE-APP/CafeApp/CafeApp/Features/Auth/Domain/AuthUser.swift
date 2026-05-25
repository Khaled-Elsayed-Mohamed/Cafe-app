import Foundation

struct AuthUser {
    let id: String
    let email: String
    let displayName: String
    let role: UserRole
}

enum UserRole {
    case customer
    case worker
    case owner
}
