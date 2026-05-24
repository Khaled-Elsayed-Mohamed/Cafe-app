// MenuRepository.swift
// Architectural contract — Domain layer protocol.
// Concrete implementations live in Features/Menu/Data/ only.
// No Firebase imports permitted in this file.

import Foundation

protocol MenuRepository {
    /// Fetches the full menu from the remote source and updates the offline cache.
    /// Throws MenuError.networkUnavailable if offline.
    func fetchMenu() async throws -> [MenuItem]

    /// Returns the last-cached menu from UserDefaults.
    /// Returns empty array if no cache exists (first launch offline).
    func fetchCachedMenu() -> [MenuItem]

    /// Emits the full menu whenever any item changes in Firestore (availability, price, etc.).
    /// Caller should fall back to fetchCachedMenu() if the stream produces no value within 2s.
    func observeMenuUpdates() -> AsyncStream<[MenuItem]>
}

// MARK: - Domain Errors

enum MenuError: Error {
    case networkUnavailable
    case decodingFailed
    case unknown(String)
}
