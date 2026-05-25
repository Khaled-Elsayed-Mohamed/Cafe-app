import Foundation
@testable import CafeApp

final class MockAuthRepository: AuthRepository {
    var stubbedUser: AuthUser?
    var shouldThrow: AuthError?

    func signIn(email: String, password: String) async throws -> AuthUser {
        if let error = shouldThrow { throw error }
        return stubbedUser ?? AuthUser(id: "test-uid", email: email, displayName: "Test User", role: .customer)
    }

    func signUp(email: String, password: String, displayName: String) async throws -> AuthUser {
        if let error = shouldThrow { throw error }
        return stubbedUser ?? AuthUser(id: "test-uid", email: email, displayName: displayName, role: .customer)
    }

    func signOut() async throws {
        if let error = shouldThrow { throw error }
        stubbedUser = nil
    }

    func currentUser() -> AuthUser? { stubbedUser }

    func observeAuthState() -> AsyncStream<AuthUser?> {
        AsyncStream { continuation in
            continuation.yield(stubbedUser)
            continuation.finish()
        }
    }
}
