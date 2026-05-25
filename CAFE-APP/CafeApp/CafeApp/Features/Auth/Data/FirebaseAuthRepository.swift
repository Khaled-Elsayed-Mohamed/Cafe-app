import Foundation
import FirebaseAuth

final class FirebaseAuthRepository: AuthRepository {

    private let keychain = KeychainManager()

    func signIn(email: String, password: String) async throws -> AuthUser {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = try await buildAuthUser(from: result.user)
            try await storeToken(for: result.user)
            return user
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws -> AuthUser {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            let user = try await buildAuthUser(from: result.user)
            try await storeToken(for: result.user)
            return user
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }

    func signOut() async throws {
        try Auth.auth().signOut()
        try? keychain.delete(forKey: "authToken")
    }

    func currentUser() -> AuthUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AuthUser(
            id: user.uid,
            email: user.email ?? "",
            displayName: user.displayName ?? "",
            role: .customer
        )
    }

    func observeAuthState() -> AsyncStream<AuthUser?> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                guard let user else {
                    continuation.yield(nil)
                    return
                }
                Task {
                    let authUser = try? await self.buildAuthUser(from: user)
                    continuation.yield(authUser)
                }
            }
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }

    // MARK: - Private

    private func buildAuthUser(from user: FirebaseAuth.User) async throws -> AuthUser {
        let tokenResult = try await user.getIDTokenResult()
        let roleClaim = tokenResult.claims["role"] as? String ?? "customer"
        let role: UserRole = switch roleClaim {
            case "worker": .worker
            case "owner": .owner
            default: .customer
        }
        return AuthUser(
            id: user.uid,
            email: user.email ?? "",
            displayName: user.displayName ?? "",
            role: role
        )
    }

    private func storeToken(for user: FirebaseAuth.User) async throws {
        let token = try await user.getIDToken()
        try keychain.save(token, forKey: "authToken")
    }

    private func mapAuthError(_ error: NSError) -> AuthError {
        switch AuthErrorCode(rawValue: error.code) {
        case .wrongPassword, .invalidEmail, .userNotFound:
            return .invalidCredentials
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkUnavailable
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
