import Foundation

struct SignInUseCase {
    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) async throws -> AuthUser {
        try await repository.signIn(email: email, password: password)
    }
}
