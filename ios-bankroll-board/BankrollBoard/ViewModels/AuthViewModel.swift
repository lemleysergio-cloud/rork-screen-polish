//
//  AuthViewModel.swift
//  BankrollBoard
//

import Foundation
import Observation

enum PasswordResetStage: Equatable {
    case request
    case verify
    case newPassword
    case complete
}

@Observable
final class AuthViewModel {
    var mode: AuthMode = .login
    var identifier: String = "" { didSet { clearError() } }
    var username: String = "" { didSet { clearError() } }
    var email: String = "" { didSet { clearError() } }
    var password: String = "" { didSet { clearError() } }
    var signUpCode: String = "" { didSet { clearError() } }

    var resetCode: String = "" { didSet { clearError() } }
    var newPassword: String = "" { didSet { clearError() } }
    var confirmedPassword: String = "" { didSet { clearError() } }

    private(set) var resetStage: PasswordResetStage = .request
    private(set) var pendingProvider: AuthProvider?
    private(set) var isUnlocking: Bool = false
    private(set) var errorMessage: String?
    private(set) var signUpChallenge: SignUpChallenge?

    private var resetChallenge: PasswordResetChallenge?
    private let service: any AuthService

    init(service: any AuthService = DemoAuthService()) {
        self.service = service
    }

    var isBusy: Bool { pendingProvider != nil || isUnlocking }
    var isAwaitingSignUpVerification: Bool { signUpChallenge != nil }

    enum QuickSignInResult {
        case signedIn(AuthSession)
        case usePassword
        case stopped
    }

    var trimmedIdentifier: String { identifier.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedUsername: String { username.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isIdentifierValid: Bool {
        trimmedIdentifier.contains("@")
            ? Self.isValidEmail(trimmedIdentifier)
            : Self.isValidUsername(trimmedIdentifier)
    }

    var isUsernameValid: Bool { Self.isValidUsername(trimmedUsername) }
    var isEmailValid: Bool { Self.isValidEmail(trimmedEmail) }
    var isPasswordValid: Bool { password.count >= 8 }

    var canSubmitCredentials: Bool {
        switch mode {
        case .login:
            isIdentifierValid && isPasswordValid
        case .signUp:
            isUsernameValid && isEmailValid && isPasswordValid
        }
    }

    var isResetCodeValid: Bool {
        resetCode.count == 6 && resetCode.allSatisfy(\.isNumber)
    }

    var isSignUpCodeValid: Bool {
        signUpCode.count == 6 && signUpCode.allSatisfy(\.isNumber)
    }

    var canSetNewPassword: Bool {
        newPassword.count >= 8 && newPassword == confirmedPassword
    }

    func setMode(_ newMode: AuthMode) {
        guard mode != newMode, !isBusy else { return }
        mode = newMode
        errorMessage = nil
        signUpChallenge = nil
        signUpCode = ""
        password = ""
        if newMode == .signUp, email.isEmpty, identifier.contains("@") {
            email = trimmedIdentifier
        }
        if newMode == .login, identifier.isEmpty {
            identifier = email.isEmpty ? username : email
        }
    }

    func clearIdentifier() { identifier = "" }
    func clearUsername() { username = "" }
    func clearEmail() { email = "" }

    func submitCredentials() async -> AuthSession? {
        guard canSubmitCredentials, !isBusy else { return nil }
        let secret = password
        switch mode {
        case .login:
            return await run(.email) { [service, trimmedIdentifier] in
                try await service.signIn(identifier: trimmedIdentifier, password: secret)
            }
        case .signUp:
            pendingProvider = .email
            errorMessage = nil
            defer { pendingProvider = nil }
            do {
                let result = try await service.signUp(
                    username: trimmedUsername,
                    email: trimmedEmail,
                    password: secret
                )
                switch result {
                case .complete(let session): return session
                case .verificationRequired(let challenge):
                    signUpChallenge = challenge
                    signUpCode = ""
                    return nil
                }
            } catch {
                setError(error)
                return nil
            }
        }
    }

    func verifySignUp() async -> AuthSession? {
        guard isSignUpCodeValid, let signUpChallenge, !isBusy else { return nil }
        return await run(.email) { [service, signUpCode] in
            try await service.verifySignUp(code: signUpCode, challenge: signUpChallenge)
        }
    }

    func resendSignUpVerification() async -> Bool {
        guard let signUpChallenge, !isBusy else { return false }
        return await runReset {
            self.signUpChallenge = try await service.resendSignUpVerification(challenge: signUpChallenge)
        }
    }

    func cancelSignUpVerification() {
        guard !isBusy else { return }
        signUpChallenge = nil
        signUpCode = ""
        errorMessage = nil
    }

    func requestPasswordReset() async -> Bool {
        guard isEmailValid, !isBusy else { return false }
        return await runReset {
            resetChallenge = try await service.requestPasswordReset(email: trimmedEmail)
            resetStage = .verify
        }
    }

    func resendPasswordReset() async -> Bool {
        await requestPasswordReset()
    }

    func verifyPasswordReset() async -> Bool {
        guard isResetCodeValid, let resetChallenge, !isBusy else { return false }
        return await runReset {
            try await service.verifyPasswordReset(code: resetCode, challenge: resetChallenge)
            resetStage = .newPassword
        }
    }

    func completePasswordReset() async -> Bool {
        guard canSetNewPassword, let resetChallenge, !isBusy else { return false }
        return await runReset {
            try await service.completePasswordReset(newPassword: newPassword, challenge: resetChallenge)
            resetStage = .complete
        }
    }

    func continueWith(_ provider: AuthProvider) async -> AuthSession? {
        guard provider == .google || provider == .apple, !isBusy else { return nil }
        return await run(provider) { [service, mode] in
            try await service.continueWith(provider, mode: mode)
        }
    }

    /// Face ID sign-in. Cancelling is silent; "Use Password" hands back to the form.
    func quickSignIn(with accounts: AccountStore) async -> QuickSignInResult {
        guard !isBusy else { return .stopped }
        isUnlocking = true
        errorMessage = nil
        defer { isUnlocking = false }
        do {
            return .signedIn(try await accounts.quickSignIn())
        } catch BiometricError.cancelled {
            return .stopped
        } catch BiometricError.fallback {
            return .usePassword
        } catch {
            setError(error)
            return .stopped
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
        } catch AuthError.cancelled {
            return nil
        } catch {
            setError(error)
            return nil
        }
    }

    private func runReset(_ operation: () async throws -> Void) async -> Bool {
        pendingProvider = .email
        errorMessage = nil
        defer { pendingProvider = nil }
        do {
            try await operation()
            return true
        } catch {
            setError(error)
            return false
        }
    }

    private func clearError() {
        if errorMessage != nil { errorMessage = nil }
    }

    private func setError(_ error: Error) {
        errorMessage = (error as? LocalizedError)?.errorDescription
            ?? "Something went wrong. Please try again."
    }

    private static func isValidEmail(_ value: String) -> Bool {
        guard !value.contains(" ") else { return false }
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        let domain = parts[1]
        guard let dot = domain.lastIndex(of: ".") else { return false }
        return dot != domain.startIndex && domain.distance(from: dot, to: domain.endIndex) > 2
    }

    private static func isValidUsername(_ value: String) -> Bool {
        guard (3...24).contains(value.count) else { return false }
        guard value.contains(where: \.isLetter) else { return false }
        return value.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
    }
}
