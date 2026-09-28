//
//  AuthService.swift
//  BankrollBoard
//
//  Authentication boundary used by the login, sign-up, and password-reset
//  screens. Production uses ClerkAuthService; the deterministic demo service
//  remains available for previews and tests.
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

nonisolated struct SignUpChallenge: Equatable, Sendable {
    let id: String
    let email: String
    let username: String
}

nonisolated enum SignUpResult: Sendable {
    case complete(AuthSession)
    case verificationRequired(SignUpChallenge)
}

nonisolated enum AuthError: LocalizedError, Sendable {
    case cancelled
    case unavailable
    case invalidResetCode
    case passwordMismatch
    case incomplete(String)
    case noActiveSession

    var errorDescription: String? {
        switch self {
        case .cancelled: "Sign-in was cancelled."
        case .unavailable: "We couldn't reach the sign-in service. Please try again."
        case .invalidResetCode: "That verification code isn't valid. Check the email and try again."
        case .passwordMismatch: "The passwords don't match."
        case .incomplete(let message): message
        case .noActiveSession: "Your session has expired. Please sign in again."
        }
    }
}

@MainActor
protocol AuthService: Sendable {
    var supportsQuickSignIn: Bool { get }
    func signIn(identifier: String, password: String) async throws -> AuthSession
    func signUp(username: String, email: String, password: String) async throws -> SignUpResult
    func verifySignUp(code: String, challenge: SignUpChallenge) async throws -> AuthSession
    func resendSignUpVerification(challenge: SignUpChallenge) async throws -> SignUpChallenge
    func requestPasswordReset(email: String) async throws -> PasswordResetChallenge
    func verifyPasswordReset(code: String, challenge: PasswordResetChallenge) async throws
    func completePasswordReset(newPassword: String, challenge: PasswordResetChallenge) async throws
    func continueWith(_ provider: AuthProvider, mode: AuthMode) async throws -> AuthSession
    func restoreSession(for account: RememberedAccount) async throws -> AuthSession
    func currentSession() async -> AuthSession?
    func signOut() async throws
}

/// Preview/test implementation. It models the same multi-step contract as a
/// real provider instead of skipping straight to a success page.
struct DemoAuthService: AuthService {
    nonisolated init() {}
    var supportsQuickSignIn: Bool { true }

    func signIn(identifier: String, password: String) async throws -> AuthSession {
        try await pause()
        return AuthSession(
            provider: .email,
            email: identifier.contains("@") ? identifier : nil,
            username: identifier.contains("@") ? nil : identifier
        )
    }

    func signUp(username: String, email: String, password: String) async throws -> SignUpResult {
        try await pause()
        return .verificationRequired(SignUpChallenge(id: UUID().uuidString, email: email, username: username))
    }

    func verifySignUp(code: String, challenge: SignUpChallenge) async throws -> AuthSession {
        try await pause(450)
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            throw AuthError.invalidResetCode
        }
        return AuthSession(provider: .email, email: challenge.email, username: challenge.username)
    }

    func resendSignUpVerification(challenge: SignUpChallenge) async throws -> SignUpChallenge {
        try await pause(450)
        return challenge
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

    func currentSession() async -> AuthSession? { nil }

    func signOut() async throws {}

    private func pause(_ milliseconds: Int = 700) async throws {
        try await Task.sleep(for: .milliseconds(milliseconds))
    }
}
