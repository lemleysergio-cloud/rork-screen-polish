//
//  AccountStore.swift
//  BankrollBoard
//
//  Shared account state: who is signed in, whether Face ID sign-in is on,
//  and what the device's biometrics can do. Shared through the environment.
//

import Foundation
import Observation

@Observable
final class AccountStore {
    private(set) var currentAccount: RememberedAccount?
    private(set) var quickSignInRecord: QuickSignInRecord?
    private(set) var biometrics: BiometricStatus = .unavailable
    private(set) var hasAnsweredOffer: Bool

    private let authenticator: BiometricAuthenticator
    private let service: any AuthService
    private let defaults: UserDefaults

    private static let currentAccountKey = "bb.currentAccount"
    private static let offerAnsweredKey = "bb.quickSignInOfferAnswered"
    private static let keychainService = "app.rork.bankrollboard.quicksignin"
    private static let keychainAccount = "remembered-account"

    init(
        service: any AuthService = DemoAuthService(),
        authenticator: BiometricAuthenticator = BiometricAuthenticator(),
        defaults: UserDefaults = .standard
    ) {
        self.service = service
        self.authenticator = authenticator
        self.defaults = defaults
        self.hasAnsweredOffer = defaults.bool(forKey: Self.offerAnsweredKey)

        if let data = defaults.data(forKey: Self.currentAccountKey) {
            currentAccount = try? JSONDecoder().decode(RememberedAccount.self, from: data)
        }
        if let data = KeychainStore.load(service: Self.keychainService, account: Self.keychainAccount) {
            quickSignInRecord = try? JSONDecoder().decode(QuickSignInRecord.self, from: data)
        }
        biometrics = authenticator.status()
    }

    // MARK: - Derived

    var biometricKind: BiometricKind { biometrics.kind }
    var canUseBiometrics: Bool { biometrics.isReady }
    var isQuickSignInEnabled: Bool { quickSignInRecord != nil }

    /// Show the Face ID button on the login screen.
    var canQuickSignIn: Bool { service.supportsQuickSignIn && isQuickSignInEnabled && canUseBiometrics }

    /// Offer to turn on Face ID right after a password sign-in.
    var shouldOfferQuickSignIn: Bool {
        service.supportsQuickSignIn && canUseBiometrics && !isQuickSignInEnabled && !hasAnsweredOffer
    }

    // MARK: - Session

    func refreshBiometrics() {
        let status = authenticator.status()
        if status != biometrics { biometrics = status }
    }

    func didSignIn(_ session: AuthSession) {
        let account = RememberedAccount(session: session)
        currentAccount = account
        if let data = try? JSONEncoder().encode(account) {
            defaults.set(data, forKey: Self.currentAccountKey)
        }
        // Keep Face ID pointed at whoever signed in most recently.
        if var record = quickSignInRecord, record.account != account {
            record.account = account
            persist(record)
        }
    }

    /// Ends the session but keeps Face ID sign-in ready for next time.
    func signOut() {
        currentAccount = nil
        defaults.removeObject(forKey: Self.currentAccountKey)
    }

    // MARK: - Face ID sign-in

    func enableQuickSignIn() async throws {
        guard let account = currentAccount else { throw BiometricError.noAccount }
        let domainState = try await authenticator.authenticate(
            reason: "Turn on \(biometricKind.title) sign-in for Bankroll Board."
        )
        persist(QuickSignInRecord(account: account, domainState: domainState ?? biometrics.domainState))
        markOfferAnswered()
    }

    func disableQuickSignIn() {
        KeychainStore.delete(service: Self.keychainService, account: Self.keychainAccount)
        quickSignInRecord = nil
    }

    func declineQuickSignInOffer() {
        markOfferAnswered()
    }

    /// Unlocks with Face ID and resumes the remembered account's session.
    func quickSignIn() async throws -> AuthSession {
        guard let record = quickSignInRecord else { throw BiometricError.noAccount }
        let domainState = try await authenticator.authenticate(reason: "Sign in to Bankroll Board.")

        // A face added since this was turned on must not unlock the account.
        if let saved = record.domainState, let domainState, saved != domainState {
            disableQuickSignIn()
            throw BiometricError.enrollmentChanged(biometricKind.title)
        }
        return try await service.restoreSession(for: record.account)
    }

    // MARK: - Private

    private func persist(_ record: QuickSignInRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        do {
            try KeychainStore.save(data, service: Self.keychainService, account: Self.keychainAccount)
            quickSignInRecord = record
        } catch {
            print("[AccountStore] Keychain save failed")
        }
    }

    private func markOfferAnswered() {
        hasAnsweredOffer = true
        defaults.set(true, forKey: Self.offerAnsweredKey)
    }
}
