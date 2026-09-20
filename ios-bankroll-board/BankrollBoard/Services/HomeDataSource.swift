//
//  HomeDataSource.swift
//  BankrollBoard
//
//  The single seam between the Home screen and the ledger behind it.
//
//  ── Wiring this to a real Plaid backend ──────────────────────────────────
//  Implement `HomeDataSource` against your API and hand it to the view model:
//
//      HomeViewModel(dataSource: PlaidHomeDataSource())
//
//  Nothing in the Home views touches networking, Plaid, or persistence, so
//  swapping the implementation is the whole integration:
//
//    • `loadSnapshot()`  — cached/local read, called on appear. Should return
//      fast and may serve stale data; the UI labels it with a synced time.
//    • `refresh(trigger:)` — hit `/transactions/sync`, persist, return fresh
//      data. Throw `HomeDataError` so the UI can tell "retry" from
//      "the user must re-authenticate".
//    • `reauthToken(for:)` — mint a Plaid Link token in update mode for a
//      broken item, so the reconnect button can open Link.
//

import Foundation

// MARK: - Protocol

nonisolated protocol HomeDataSource: Sendable {
    /// Fast read of whatever is already known, typically from a local cache.
    func loadSnapshot() async throws -> HomeSnapshot

    /// Pull fresh data from the bank. Throws `HomeDataError` on failure.
    func refresh(trigger: HomeSyncTrigger) async throws -> HomeSnapshot

    /// Link token (update mode) for repairing a broken connection.
    func reauthToken(for accountId: String) async throws -> String
}

// MARK: - Seed implementation

/// Stand-in ledger used until the Plaid backend is connected.
///
/// It models the shapes the real source must produce — settled versus pending,
/// per-window deltas, connection health — so the UI is exercised end to end.
/// Refreshes settle one pending transfer at a time, which is exactly what a
/// real `/transactions/sync` does as the bank clears money.
nonisolated final class SeedHomeDataSource: HomeDataSource, @unchecked Sendable {
    private let now: Date
    private let lock = NSLock()
    private var snapshot: HomeSnapshot
    /// Drives the demo: each refresh settles the next pending transfer.
    private var refreshCount = 0

    init(now: Date = Date()) {
        self.now = now
        self.snapshot = SeedHomeDataSource.makeSnapshot(now: now, settledIds: [])
    }

    func loadSnapshot() async throws -> HomeSnapshot {
        try await Task.sleep(for: .milliseconds(220))
        return lock.withLock { snapshot }
    }

    func refresh(trigger: HomeSyncTrigger) async throws -> HomeSnapshot {
        // Network latency the real client will also have; keeps the spinner honest.
        try await Task.sleep(for: .milliseconds(trigger == .background ? 500 : 1_150))

        return lock.withLock {
            refreshCount += 1
            // Settle pending money progressively, oldest estimate first.
            let pendingIds = snapshot.transfers
                .filter { $0.status == .pending }
                .sorted { ($0.expectedDate ?? .distantFuture) < ($1.expectedDate ?? .distantFuture) }
                .map(\.id)
            let settledIds = Set(pendingIds.prefix(refreshCount))

            var updated = SeedHomeDataSource.makeSnapshot(now: now, settledIds: settledIds)
            updated.generatedAt = Date()
            updated.accounts = updated.accounts.map { account in
                var account = account
                account.lastSyncedAt = Date()
                return account
            }
            snapshot = updated
            return updated
        }
    }

    func reauthToken(for accountId: String) async throws -> String {
        try await Task.sleep(for: .milliseconds(400))
        return "link-sandbox-seed-\(accountId)"
    }

    /// Builds a snapshot where `settledIds` have cleared the bank, moving their
    /// value out of pending and into the settled balance.
    private static func makeSnapshot(now: Date, settledIds: Set<String>) -> HomeSnapshot {
        let base = HomeSeed.transfers(now: now)
        var movedCents = 0

        let transfers = base.map { transfer -> HomeTransfer in
            guard transfer.status == .pending, settledIds.contains(transfer.id) else {
                return transfer
            }
            movedCents += transfer.cents
            return HomeTransfer(
                id: transfer.id,
                casinoId: transfer.casinoId,
                direction: transfer.direction,
                cents: transfer.cents,
                date: transfer.date,
                status: .settled,
                expectedDate: nil
            )
        }

        var deltas: [HomeTimeframe: Int] = [:]
        for timeframe in HomeTimeframe.allCases {
            deltas[timeframe] = HomeSeed.periodDeltaCents(for: timeframe) + movedCents
        }

        return HomeSnapshot(
            settledCents: HomeSeed.settledCents + movedCents,
            transfers: transfers,
            periodDeltas: deltas,
            accounts: [
                LinkedAccount(
                    id: "acc_checking",
                    itemId: "item_seed_1",
                    institutionName: "Chase",
                    mask: "4417",
                    connection: .healthy,
                    lastSyncedAt: now.addingTimeInterval(-420)
                ),
                LinkedAccount(
                    id: "acc_savings",
                    itemId: "item_seed_2",
                    institutionName: "Ally",
                    mask: "9032",
                    connection: .healthy,
                    lastSyncedAt: now.addingTimeInterval(-420)
                )
            ],
            generatedAt: now
        )
    }
}
