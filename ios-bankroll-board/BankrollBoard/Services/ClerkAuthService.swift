//
//  ClerkAuthService.swift
//  BankrollBoard
//

import AuthenticationServices
import ClerkKit
import Foundation

enum AuthConfiguration {
    static var publishableKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "CLERK_PUBLISHABLE_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static func configureClerk() {
        guard publishableKey.hasPrefix("pk_") else {
            assertionFailure("Missing CLERK_PUBLISHABLE_KEY build setting")
            return
        }
        Clerk.configure(publishableKey: publishableKey)
    }
}

@MainActor
final class ClerkAuthService: AuthService, @unchecked Sendable {
    nonisolated init() {}
    var supportsQuickSignIn: Bool { false }

    private var clerk: Clerk { Clerk.shared }

    func signIn(identifier: String, password: String) async throws -> AuthSession {
        let signIn = try await clerk.auth.signInWithPassword(identifier: identifier, password: password)
        guard signIn.status == .complete else {
            throw continuationError(for: signIn.status)
        }
        return session(provider: .email, fallbackEmail: identifier.contains("@") ? identifier : nil,
                       fallbackUsername: identifier.contains("@") ? nil : identifier)
    }

    func signUp(username: String, email: String, password: String) async throws -> SignUpResult {
        var signUp = try await clerk.auth.signUp(
            emailAddress: email,
            password: password,
            username: username
        )

        if signUp.status == .complete {
            return .complete(session(provider: .email, fallbackEmail: email, fallbackUsername: username))
        }

        signUp = try await signUp.sendEmailCode()
        return .verificationRequired(
            SignUpChallenge(id: signUp.id, email: email, username: username)
        )
    }

    func verifySignUp(code: String, challenge: SignUpChallenge) async throws -> AuthSession {
        guard let pending = clerk.auth.currentSignUp, pending.id == challenge.id else {
            throw AuthError.incomplete("This verification request expired. Please create your account again.")
        }
        let signUp = try await pending.verifyEmailCode(code)
        guard signUp.status == .complete else {
            let fields = signUp.missingFields.map(\.rawValue).joined(separator: ", ")
            let detail = fields.isEmpty ? "additional account information" : fields
            throw AuthError.incomplete("Your account still needs \(detail). Please try again.")
        }
        return session(provider: .email, fallbackEmail: challenge.email, fallbackUsername: challenge.username)
    }

    func resendSignUpVerification(challenge: SignUpChallenge) async throws -> SignUpChallenge {
        guard let pending = clerk.auth.currentSignUp, pending.id == challenge.id else {
            throw AuthError.incomplete("This verification request expired. Please create your account again.")
        }
        let signUp = try await pending.sendEmailCode()
        return SignUpChallenge(id: signUp.id, email: challenge.email, username: challenge.username)
    }

    func requestPasswordReset(email: String) async throws -> PasswordResetChallenge {
        let signIn = try await clerk.auth.signIn(email)
        let prepared = try await signIn.sendResetPasswordEmailCode()
        return PasswordResetChallenge(id: prepared.id, email: email)
    }

    func verifyPasswordReset(code: String, challenge: PasswordResetChallenge) async throws {
        guard let pending = clerk.auth.currentSignIn, pending.id == challenge.id else {
            throw AuthError.incomplete("This reset request expired. Please request a new code.")
        }
        let signIn = try await pending.verifyCode(code)
        guard signIn.status == .needsNewPassword else {
            throw AuthError.invalidResetCode
        }
    }

    func completePasswordReset(newPassword: String, challenge: PasswordResetChallenge) async throws {
        guard let pending = clerk.auth.currentSignIn, pending.id == challenge.id else {
            throw AuthError.incomplete("This reset request expired. Please request a new code.")
        }
        let signIn = try await pending.resetPassword(newPassword: newPassword, signOutOfOtherSessions: true)
        guard signIn.status == .complete else {
            throw continuationError(for: signIn.status)
        }

        // Clerk completes password reset by creating a session. This screen promises
        // to return to login, so close that temporary session before showing success.
        try await clerk.auth.signOut()
    }

    func continueWith(_ provider: AuthProvider, mode: AuthMode) async throws -> AuthSession {
        do {
            let result: TransferFlowResult
            switch (provider, mode) {
            case (.google, .login):
                result = try await clerk.auth.signInWithOAuth(provider: .google)
            case (.google, .signUp):
                result = try await clerk.auth.signUpWithOAuth(provider: .google)
            case (.apple, .login):
                result = try await clerk.auth.signInWithApple()
            case (.apple, .signUp):
                result = try await clerk.auth.signUpWithApple()
            case (.email, _):
                throw AuthError.unavailable
            }

            try requireComplete(result)
            return session(provider: provider)
        } catch is CancellationError {
            throw AuthError.cancelled
        } catch let error as ASAuthorizationError where error.code == .canceled {
            throw AuthError.cancelled
        }
    }

    func restoreSession(for account: RememberedAccount) async throws -> AuthSession {
        guard clerk.session != nil else { throw AuthError.noActiveSession }
        return session(provider: account.provider, fallbackEmail: account.email)
    }

    func currentSession() async -> AuthSession? {
        if clerk.session == nil {
            _ = try? await clerk.refreshClient()
        }
        guard clerk.session != nil else { return nil }
        return session(provider: inferredProvider())
    }

    func signOut() async throws {
        try await clerk.auth.signOut()
    }

    private func requireComplete(_ result: TransferFlowResult) throws {
        switch result {
        case .signIn(let signIn) where signIn.status == .complete:
            return
        case .signUp(let signUp) where signUp.status == .complete:
            return
        case .signIn(let signIn):
            throw continuationError(for: signIn.status)
        case .signUp:
            throw AuthError.incomplete("Please finish the remaining account setup before continuing.")
        }
    }

    private func continuationError(for status: SignIn.Status) -> AuthError {
        switch status {
        case .needsSecondFactor:
            .incomplete("This account requires an additional verification step. Please use the web app to sign in.")
        case .needsNewPassword:
            .incomplete("You need to set a new password before signing in.")
        case .needsClientTrust:
            .incomplete("This device needs additional verification before it can sign in.")
        default:
            .incomplete("Sign-in could not be completed. Please check your details and try again.")
        }
    }

    private func session(
        provider: AuthProvider,
        fallbackEmail: String? = nil,
        fallbackUsername: String? = nil
    ) -> AuthSession {
        AuthSession(
            provider: provider,
            email: clerk.user?.primaryEmailAddress?.emailAddress ?? fallbackEmail,
            username: clerk.user?.username ?? fallbackUsername
        )
    }

    private func inferredProvider() -> AuthProvider {
        guard let account = clerk.user?.externalAccounts.first else { return .email }
        switch account.provider {
        case "google": return .google
        case "apple": return .apple
        default: return .email
        }
    }
}
