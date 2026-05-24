// AuthRepository.swift
// Architectural contract — Domain layer protocol.
// Concrete implementations live in Features/Auth/Data/ only.
// No Firebase imports permitted in this file.

import Foundation

protocol AuthRepository {
    /// Signs in an existing customer or staff member.
    func signIn(email: String, password: String) async throws -> AuthUser

    /// Registers a new customer account. Triggers onCreateUser Cloud Function
    /// which generates the membership barcode and creates the loyalty_accounts document.
    func signUp(email: String, password: String, displayName: String) async throws -> AuthUser

    /// Signs out the current user.
    func signOut() async throws

    /// Returns the currently authenticated user, or nil if no session exists.
    func currentUser() -> AuthUser?

    /// Emits the current user whenever auth state changes (sign in, sign out, token refresh).
    func observeAuthState() -> AsyncStream<AuthUser?>
}

// MARK: - Domain Errors

enum AuthError: Error {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkUnavailable
    case unknown(String)
}
