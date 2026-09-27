//
//  AuthService.swift
//  BankrollBoard
//
//  Sign-in seam. The screen only talks to `AuthService`, so a real provider
//  (Rork Auth, Supabase, Firebase…) can replace `DemoAuthService` without
//  touching any UI.
//

import Foundation

nonisolated enum AuthProvider: String, Sendable {
    case email
    case google
    case apple
}

nonisolated struct AuthSession: Sendable {
    let provider: AuthProvider
    let email: String?
}

nonisolated enum AuthError: LocalizedError, Sendable {
    case cancelled
    case unavailable

    var errorDescription: String? {
        switch self {
        case .cancelled: "Sign-in was cancelled."
        case .unavailable: "We couldn't reach the sign-in service. Please try again."
        }
    }
}

nonisolated protocol AuthService: Sendable {
    /// Starts an email sign-in or sign-up for the given address.
    func continueWithEmail(_ email: String) async throws -> AuthSession

    /// Starts a third-party sign-in flow.
    func continueWith(_ provider: AuthProvider) async throws -> AuthSession
}

/// Stand-in used until a real auth backend is connected: waits briefly, then succeeds.
nonisolated struct DemoAuthService: AuthService {
    func continueWithEmail(_ email: String) async throws -> AuthSession {
        try await Task.sleep(for: .milliseconds(900))
        return AuthSession(provider: .email, email: email)
    }

    func continueWith(_ provider: AuthProvider) async throws -> AuthSession {
        try await Task.sleep(for: .milliseconds(900))
        return AuthSession(provider: provider, email: nil)
    }
}
