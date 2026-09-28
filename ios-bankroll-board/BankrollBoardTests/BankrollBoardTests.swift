//
//  BankrollBoardTests.swift
//  BankrollBoardTests
//

import Testing
@testable import BankrollBoard

@MainActor
struct AuthFlowTests {
    @Test func loginAcceptsEmailOrUsernameButNotPhoneNumbers() {
        let model = AuthViewModel(service: AuthStub())
        model.password = "password123"

        model.identifier = "player.one"
        #expect(model.canSubmitCredentials)

        model.identifier = "player@example.com"
        #expect(model.canSubmitCredentials)

        model.identifier = "5558675309"
        #expect(!model.canSubmitCredentials)
    }

    @Test func signUpRequiresUsernameEmailAndEightCharacterPassword() async {
        let model = AuthViewModel(service: AuthStub())
        model.setMode(.signUp)
        model.username = "board_player"
        model.email = "player@example.com"
        model.password = "1234567"
        #expect(!model.canSubmitCredentials)

        model.password = "12345678"
        #expect(model.canSubmitCredentials)
        let pendingSession = await model.submitCredentials()
        #expect(pendingSession == nil)
        #expect(model.isAwaitingSignUpVerification)

        model.signUpCode = "123456"
        let session = await model.verifySignUp()
        #expect(session?.username == "board_player")
        #expect(session?.email == "player@example.com")
    }

    @Test func passwordResetMovesThroughEveryRequiredStep() async {
        let model = AuthViewModel(service: AuthStub())
        model.email = "player@example.com"

        #expect(await model.requestPasswordReset())
        #expect(model.resetStage == .verify)

        model.resetCode = "123456"
        #expect(await model.verifyPasswordReset())
        #expect(model.resetStage == .newPassword)

        model.newPassword = "new-password"
        model.confirmedPassword = "new-password"
        #expect(await model.completePasswordReset())
        #expect(model.resetStage == .complete)
    }

    @Test func mismatchedPasswordsCannotCompleteReset() async {
        let model = AuthViewModel(service: AuthStub())
        model.email = "player@example.com"
        _ = await model.requestPasswordReset()
        model.resetCode = "123456"
        _ = await model.verifyPasswordReset()
        model.newPassword = "new-password"
        model.confirmedPassword = "different-password"

        #expect(!model.canSetNewPassword)
        #expect(!(await model.completePasswordReset()))
        #expect(model.resetStage == .newPassword)
    }
}

private struct AuthStub: AuthService {
    var supportsQuickSignIn: Bool { false }

    func signIn(identifier: String, password: String) async throws -> AuthSession {
        AuthSession(
            provider: .email,
            email: identifier.contains("@") ? identifier : nil,
            username: identifier.contains("@") ? nil : identifier
        )
    }

    func signUp(username: String, email: String, password: String) async throws -> SignUpResult {
        .verificationRequired(SignUpChallenge(id: "signup-test", email: email, username: username))
    }

    func verifySignUp(code: String, challenge: SignUpChallenge) async throws -> AuthSession {
        AuthSession(provider: .email, email: challenge.email, username: challenge.username)
    }

    func resendSignUpVerification(challenge: SignUpChallenge) async throws -> SignUpChallenge { challenge }

    func requestPasswordReset(email: String) async throws -> PasswordResetChallenge {
        PasswordResetChallenge(id: "test", email: email)
    }

    func verifyPasswordReset(code: String, challenge: PasswordResetChallenge) async throws {}
    func completePasswordReset(newPassword: String, challenge: PasswordResetChallenge) async throws {}

    func continueWith(_ provider: AuthProvider, mode: AuthMode) async throws -> AuthSession {
        AuthSession(provider: provider, email: nil)
    }

    func restoreSession(for account: RememberedAccount) async throws -> AuthSession {
        AuthSession(provider: account.provider, email: account.email)
    }

    func currentSession() async -> AuthSession? { nil }
    func signOut() async throws {}
}
