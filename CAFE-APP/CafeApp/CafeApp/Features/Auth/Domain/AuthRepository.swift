import Foundation

protocol AuthRepository {
    func signIn(email: String, password: String) async throws -> AuthUser
    func signUp(email: String, password: String, displayName: String) async throws -> AuthUser
    func signOut() async throws
    func currentUser() -> AuthUser?
    func observeAuthState() -> AsyncStream<AuthUser?>
}

enum AuthError: Error {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkUnavailable
    case unknown(String)
}
