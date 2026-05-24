// CafeConfigRepository.swift
// Architectural contract — Core/CafeConfig protocol.
// Concrete implementations live in Core/CafeConfig/Data/ only.
// No Firebase imports permitted in this file.

import Foundation

protocol CafeConfigRepository {
    /// Fetches the current café operating configuration from Firestore.
    /// Used by PlaceOrderUseCase to validate the requested ready-by time (FR-004).
    func fetchConfig() async throws -> CafeConfig

    /// Emits the config whenever it changes (e.g., early closure, hour changes).
    func observeConfig() -> AsyncStream<CafeConfig>
}

// MARK: - Domain Errors

enum CafeConfigError: Error {
    case configNotFound
    case networkUnavailable
    case unknown(String)
}
