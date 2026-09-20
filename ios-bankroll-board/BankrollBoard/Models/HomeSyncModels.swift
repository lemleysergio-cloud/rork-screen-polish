//
//  HomeSyncModels.swift
//  BankrollBoard
//
//  Sync state for the Home screen: what the ledger looks like right now, which
//  bank connections back it, and how the most recent refresh went.
//
//  These types are the contract between the UI and whatever supplies the data.
//  A real Plaid integration only needs to produce a `HomeSnapshot`; nothing in
//  the views reaches past this boundary.
//

import Foundation

// MARK: - Snapshot

/// A complete, self-consistent picture of the user's bankroll at one moment.
///
/// Everything Home renders comes from here, so a refresh is a single atomic
/// swap rather than a series of partial updates that could disagree.
nonisolated struct HomeSnapshot: Equatable, Sendable {
    /// Settled net bankroll in cents. Pending money is deliberately excluded.
    var settledCents: Int
    /// Every transfer the ledger knows about, settled and pending alike.
    var transfers: [HomeTransfer]
    /// Net movement per chart window, in cents.
    var periodDeltas: [HomeTimeframe: Int]
    /// Bank connections feeding this snapshot.
    var accounts: [LinkedAccount]
    /// When the backend produced this data.
    var generatedAt: Date

    static let empty = HomeSnapshot(
        settledCents: 0,
        transfers: [],
        periodDeltas: [:],
        accounts: [],
        generatedAt: .distantPast
    )

    func delta(for timeframe: HomeTimeframe) -> Int {
        periodDeltas[timeframe] ?? 0
    }

    /// Connections that can no longer sync without the user stepping in.
    var accountsNeedingAttention: [LinkedAccount] {
        accounts.filter { $0.connection != .healthy }
    }
}

// MARK: - Linked accounts

/// Health of a single bank connection, mirroring the states Plaid reports.
nonisolated enum AccountConnectionState: String, Equatable, Sendable {
    /// Syncing normally.
    case healthy
    /// Plaid returned `ITEM_LOGIN_REQUIRED`; the user must re-enter credentials.
    case needsReauth
    /// The institution is down or rate limiting; retry later, no user action needed.
    case degraded

    var label: String {
        switch self {
        case .healthy: "Connected"
        case .needsReauth: "Action needed"
        case .degraded: "Delayed"
        }
    }

    var symbol: String {
        switch self {
        case .healthy: "checkmark.circle.fill"
        case .needsReauth: "exclamationmark.triangle.fill"
        case .degraded: "clock.badge.exclamationmark.fill"
        }
    }

    var requiresUserAction: Bool { self == .needsReauth }
}

/// One bank account linked through Plaid.
nonisolated struct LinkedAccount: Identifiable, Equatable, Sendable {
    let id: String
    /// Plaid item identifier — the handle used to re-open Link for repair.
    let itemId: String
    let institutionName: String
    /// Last four digits of the account number.
    let mask: String
    var connection: AccountConnectionState
    var lastSyncedAt: Date?

    var displayName: String { "\(institutionName) ••\(mask)" }
}

// MARK: - Sync status

/// What kicked off a sync. Lets the UI stay quiet for background work and
/// speak up for anything the user asked for directly.
nonisolated enum HomeSyncTrigger: Equatable, Sendable {
    case initialLoad
    case manual
    case pullToRefresh
    case background

    /// Background refreshes shouldn't interrupt with a banner.
    var isUserInitiated: Bool {
        switch self {
        case .manual, .pullToRefresh: true
        case .initialLoad, .background: false
        }
    }
}

nonisolated enum HomeSyncPhase: Equatable, Sendable {
    case idle
    case syncing
    /// Finished, with what actually changed so the banner can say something useful.
    case succeeded(newTransfers: Int, newlySettled: Int)
    case failed(message: String, isRecoverable: Bool)
}

nonisolated struct HomeSyncStatus: Equatable, Sendable {
    var phase: HomeSyncPhase = .idle
    var trigger: HomeSyncTrigger = .initialLoad
    var lastSyncedAt: Date?

    var isSyncing: Bool { phase == .syncing }

    static let idle = HomeSyncStatus()
}

// MARK: - Errors

/// Failure modes a Plaid-backed ledger realistically hits.
nonisolated enum HomeDataError: LocalizedError, Equatable, Sendable {
    case offline
    case reauthRequired(institution: String)
    case rateLimited
    case server(String)

    var errorDescription: String? {
        switch self {
        case .offline:
            "No connection. Your numbers may be out of date."
        case .reauthRequired(let institution):
            "\(institution) needs you to sign in again."
        case .rateLimited:
            "Your bank is rate limiting refreshes. Try again in a minute."
        case .server(let detail):
            detail
        }
    }

    /// Whether a plain retry stands a chance, or the user must do something first.
    var isRecoverable: Bool {
        switch self {
        case .offline, .rateLimited, .server: true
        case .reauthRequired: false
        }
    }
}

// MARK: - Relative time

/// "Just now" / "2 min ago" / "Yesterday" for the last-synced caption.
nonisolated func homeRelativeTime(_ date: Date?, now: Date = Date()) -> String {
    guard let date else { return "Never synced" }
    let elapsed = now.timeIntervalSince(date)
    if elapsed < 60 { return "Just now" }
    if elapsed < 3_600 { return "\(Int(elapsed / 60)) min ago" }
    if elapsed < 86_400 {
        let hours = Int(elapsed / 3_600)
        return "\(hours) hr\(hours == 1 ? "" : "s") ago"
    }
    let days = Int(elapsed / 86_400)
    if days == 1 { return "Yesterday" }
    if days < 7 { return "\(days) days ago" }
    return homeShortDate(date)
}
