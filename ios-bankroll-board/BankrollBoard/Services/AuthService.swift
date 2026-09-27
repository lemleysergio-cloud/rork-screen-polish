//
//  AuthService.swift
//  BankrollBoard
//
//  Authentication boundary used by the login, sign-up, and password-reset
//  screens. The bundled service is deterministic so previews and tests can
//  exercise every state without network credentials. Production builds should
//  inject the app's live provider through AuthViewModel and AccountStore.
//

import Foundation

nonisolated enum AuthMode: String, CaseIterable, Sendable {
    case login
    case signUp

    var title: String {
        switch self {
        case .login: "Log In"
        case .signUp: "Sign Up"
        }
    }
}

nonisolated enum AuthProvider: String, Codable, Sendable {
    case email
    case google
    case apple
}

nonisolated struct AuthSession: Sendable {
    let provider: AuthProvider
    let email: String?
    let username: String?

    init(provider: AuthProvider, email: String?, username: String? = nil) {
        self.provider = provider
        self.email = email
        self.username = username
    }
}

nonisolated struct PasswordResetChallenge: Equatable, Sendable {
    let id: String
    let email: String
}

nonisolated enum AuthError: LocalizedError, Sendable {
    case cancelled
    case unavailable
    case invalidResetCode
    case passwordMismatch

    var errorDescription: String? {
        switch self {
        case .cancelled: "Sign-in was cancelled."
        case .unavailable: "We couldn't reach the sign-in service. Please try again."
        case .invalidResetCode: "That verification code isn't valid. Check the email and try again."
        case .passwordMismatch: "The passwords don't match."
        }
    }
}

nonisolated protocol AuthService: Sendable {
    func signIn(identifier: String, password: String) async throws -> AuthSession
    func signUp(username: String, email: String, password: String) async throws -> AuthSession
    func requestPasswordReset(email: String) async throws -> PasswordResetChallenge
    func verifyPasswordReset(code: String, challenge: PasswordResetChallenge) async throws
    func completePasswordReset(newPassword: String, challenge: PasswordResetChallenge) async throws
    func continueWith(_ provider: AuthProvider, mode: AuthMode) async throws -> AuthSession
    func restoreSession(for account: RememberedAccount) async throws -> AuthSession
}

/// Preview/test implementation. It models the same multi-step contract as a
/// real provider instead of skipping straight to a success page.
nonisolated struct DemoAuthService: AuthService {
    func signIn(identifier: String, password: String) async throws -> AuthSession {
        try await pause()
        return AuthSession(
            provider: .email,
            email: identifier.contains("@") ? identifier : nil,
            username: identifier.contains("@") ? nil : identifier
        )
    }

    func signUp(username: String, email: String, password: String) async throws -> AuthSession {
        try await pause()
        return AuthSession(provider: .email, email: email, username: username)
    }

    func requestPasswordReset(email: String) async throws -> PasswordResetChallenge {
        try await pause()
        return PasswordResetChallenge(id: UUID().uuidString, email: email)
    }

    func verifyPasswordReset(code: String, challenge: PasswordResetChallenge) async throws {
        try await pause(450)
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            throw AuthError.invalidResetCode
        }
    }

    func completePasswordReset(newPassword: String, challenge: PasswordResetChallenge) async throws {
        try await pause()
    }

    func continueWith(_ provider: AuthProvider, mode: AuthMode) async throws -> AuthSession {
        try await pause()
        return AuthSession(provider: provider, email: nil)
    }

    func restoreSession(for account: RememberedAccount) async throws -> AuthSession {
        try await pause(450)
        return AuthSession(provider: account.provider, email: account.email)
    }

    private func pause(_ milliseconds: Int = 700) async throws {
        try await Task.sleep(for: .milliseconds(milliseconds))
    }
}
