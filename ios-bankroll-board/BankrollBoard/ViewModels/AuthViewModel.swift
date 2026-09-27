//
//  AuthViewModel.swift
//  BankrollBoard
//

import Foundation
import Observation

@Observable
final class AuthViewModel {
    var email: String = "" {
        didSet { if errorMessage != nil { errorMessage = nil } }
    }
    private(set) var pendingProvider: AuthProvider?
    private(set) var errorMessage: String?

    private let service: any AuthService

    init(service: any AuthService = DemoAuthService()) {
        self.service = service
    }

    var isBusy: Bool { pendingProvider != nil }

    var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Lightweight shape check — the server remains the source of truth.
    var isEmailValid: Bool {
        let value = trimmedEmail
        guard !value.contains(" ") else { return false }
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        let domain = parts[1]
        guard let dot = domain.lastIndex(of: ".") else { return false }
        return dot != domain.startIndex && domain.distance(from: dot, to: domain.endIndex) > 2
    }

    func clearEmail() {
        email = ""
    }

    func submitEmail() async -> AuthSession? {
        guard isEmailValid, !isBusy else { return nil }
        return await run(.email) { [service, trimmedEmail] in
            try await service.continueWithEmail(trimmedEmail)
        }
    }

    func continueWith(_ provider: AuthProvider) async -> AuthSession? {
        guard !isBusy else { return nil }
        return await run(provider) { [service] in
            try await service.continueWith(provider)
        }
    }

    private func run(
        _ provider: AuthProvider,
        _ operation: @escaping @Sendable () async throws -> AuthSession
    ) async -> AuthSession? {
        pendingProvider = provider
        errorMessage = nil
        defer { pendingProvider = nil }
        do {
            return try await operation()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Something went wrong. Please try again."
            return nil
        }
    }
}
