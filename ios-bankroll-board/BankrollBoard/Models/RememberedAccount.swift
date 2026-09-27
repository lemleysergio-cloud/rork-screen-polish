//
//  RememberedAccount.swift
//  BankrollBoard
//

import Foundation

/// The account a signed-in user is using, kept so Face ID can resume it later.
nonisolated struct RememberedAccount: Codable, Equatable, Sendable {
    let provider: AuthProvider
    let email: String?

    init(provider: AuthProvider, email: String?) {
        self.provider = provider
        self.email = email
    }

    init(session: AuthSession) {
        self.init(provider: session.provider, email: session.email)
    }

    var displayName: String {
        if let email { return email }
        switch provider {
        case .google: return "Google account"
        case .apple: return "Apple account"
        case .email: return "Your account"
        }
    }

    /// Email with the local part hidden, e.g. "j•••@gmail.com".
    var maskedName: String {
        guard let email, let at = email.firstIndex(of: "@"), let first = email.first else {
            return displayName
        }
        return "\(first)•••\(email[at...])"
    }

    var providerLine: String {
        switch provider {
        case .email: return "Signed in with email"
        case .google: return "Signed in with Google"
        case .apple: return "Signed in with Apple"
        }
    }
}

/// What gets stored in the Keychain when Face ID sign-in is turned on.
/// `domainState` fingerprints the enrolled faces so a newly added face can't
/// unlock the account without the password.
nonisolated struct QuickSignInRecord: Codable, Equatable, Sendable {
    var account: RememberedAccount
    let domainState: Data?
}
