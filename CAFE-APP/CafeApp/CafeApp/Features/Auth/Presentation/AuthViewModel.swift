import Foundation
import Observation

@Observable
final class AuthViewModel {
    var currentUser: AuthUser?
    var isLoading = false
    var errorMessage: String?

    private let repository: any AuthRepository
    private let signInUseCase: SignInUseCase
    private let registerUseCase: RegisterUseCase

    init(repository: any AuthRepository) {
        self.repository = repository
        self.signInUseCase = SignInUseCase(repository: repository)
        self.registerUseCase = RegisterUseCase(repository: repository)
        self.currentUser = repository.currentUser()
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await signInUseCase.execute(email: email, password: password)
        } catch let error as AuthError {
            errorMessage = message(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            currentUser = try await registerUseCase.execute(
                email: email,
                password: password,
                displayName: displayName
            )
        } catch let error as AuthError {
            errorMessage = message(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        do {
            try await repository.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func observeAuthState() {
        Task {
            for await user in repository.observeAuthState() {
                currentUser = user
            }
        }
    }

    private func message(for error: AuthError) -> String {
        switch error {
        case .invalidCredentials: "Invalid email or password."
        case .emailAlreadyInUse: "An account with this email already exists."
        case .weakPassword: "Password must be at least 6 characters."
        case .networkUnavailable: "No internet connection. Please try again."
        case .unknown(let msg): msg
        }
    }
}
