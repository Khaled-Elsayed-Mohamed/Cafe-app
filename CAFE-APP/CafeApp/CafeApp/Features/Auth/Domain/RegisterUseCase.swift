import Foundation

struct RegisterUseCase {
    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String, displayName: String) async throws -> AuthUser {
        try await repository.signUp(email: email, password: password, displayName: displayName)
    }
}
