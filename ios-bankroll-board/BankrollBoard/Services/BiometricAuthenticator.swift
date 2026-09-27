//
//  BiometricAuthenticator.swift
//  BankrollBoard
//
//  Thin wrapper over LocalAuthentication: reports what the device supports
//  and runs the Face ID / Touch ID check with friendly errors.
//

import Foundation
import LocalAuthentication

nonisolated enum BiometricKind: Sendable, Equatable {
    case faceID
    case touchID
    case opticID
    case none

    init(_ type: LABiometryType) {
        switch type {
        case .faceID: self = .faceID
        case .touchID: self = .touchID
        case .opticID: self = .opticID
        case .none: self = .none
        @unknown default: self = .none
        }
    }

    var title: String {
        switch self {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        case .none: "Face ID"
        }
    }

    var symbol: String {
        switch self {
        case .faceID, .none: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        }
    }
}

nonisolated enum BiometricError: LocalizedError, Sendable, Equatable {
    case cancelled
    case fallback
    case noAccount
    case lockedOut(String)
    case notEnrolled(String)
    case unavailable(String)
    case failed(String)
    case enrollmentChanged(String)

    init(code: LAError.Code?, kind: BiometricKind) {
        switch code {
        case .userCancel, .appCancel, .systemCancel, .notInteractive:
            self = .cancelled
        case .userFallback:
            self = .fallback
        case .biometryLockout:
            self = .lockedOut(kind.title)
        case .biometryNotEnrolled, .passcodeNotSet:
            self = .notEnrolled(kind.title)
        case .biometryNotAvailable:
            self = .unavailable(kind.title)
        default:
            self = .failed(kind.title)
        }
    }

    var errorDescription: String? {
        switch self {
        case .cancelled, .fallback:
            nil
        case .noAccount:
            "Sign in with your password first, then turn this on."
        case .lockedOut(let name):
            "\(name) is locked after too many tries. Sign in with your password."
        case .notEnrolled(let name):
            "\(name) isn't set up on this iPhone. Add it in iOS Settings."
        case .unavailable(let name):
            "\(name) isn't available right now. Sign in with your password."
        case .failed(let name):
            "\(name) didn't recognize you. Try again or use your password."
        case .enrollmentChanged(let name):
            "Your \(name) settings changed. Sign in with your password, then turn \(name) back on in Settings."
        }
    }
}

/// What the device can do right now.
nonisolated struct BiometricStatus: Sendable, Equatable {
    let kind: BiometricKind
    let isReady: Bool
    let domainState: Data?
    /// Plain-language reason when `isReady` is false.
    let unavailableReason: String?

    static let unavailable = BiometricStatus(
        kind: .none,
        isReady: false,
        domainState: nil,
        unavailableReason: "Not available on this device."
    )
}

struct BiometricAuthenticator {
    private let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics

    func status() -> BiometricStatus {
        let context = LAContext()
        var error: NSError?
        let isReady = context.canEvaluatePolicy(policy, error: &error)
        // `biometryType` is only filled in after `canEvaluatePolicy` runs.
        let kind = BiometricKind(context.biometryType)

        guard !isReady else {
            return BiometricStatus(
                kind: kind,
                isReady: true,
                domainState: context.evaluatedPolicyDomainState,
                unavailableReason: nil
            )
        }

        let code = error.flatMap { LAError.Code(rawValue: $0.code) }
        let reason: String
        switch code {
        case .biometryNotEnrolled:
            reason = "Set up \(kind.title) in iOS Settings to use this."
        case .passcodeNotSet:
            reason = "Set a passcode in iOS Settings to use \(kind.title)."
        case .biometryLockout:
            reason = "\(kind.title) is locked. Unlock your iPhone with your passcode first."
        default:
            reason = kind == .none ? "Not available on this device." : "\(kind.title) isn't available right now."
        }
        return BiometricStatus(kind: kind, isReady: false, domainState: nil, unavailableReason: reason)
    }

    /// Runs the biometric check. Returns the enrollment fingerprint on success.
    func authenticate(reason: String) async throws -> Data? {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Password"
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            let code = error.flatMap { LAError.Code(rawValue: $0.code) }
            throw BiometricError(code: code, kind: BiometricKind(context.biometryType))
        }
        let kind = BiometricKind(context.biometryType)

        do {
            _ = try await context.evaluatePolicy(policy, localizedReason: reason)
            return context.evaluatedPolicyDomainState
        } catch let laError as LAError {
            throw BiometricError(code: laError.code, kind: kind)
        } catch {
            throw BiometricError(code: nil, kind: kind)
        }
    }
}
