//
//  StatsDataSource.swift
//  BankrollBoard
//
//  The seam between the Stats screen and the transfer ledger behind it,
//  mirroring HomeDataSource so a real backend can drop in later.
//
//  ── Wiring this to a real backend ────────────────────────────────────────
//  Implement `StatsDataSource` against your API and hand it to the model:
//
//      StatsViewModel(dataSource: PlaidStatsDataSource())
//
//    • `loadLedger()`   — cached/local read, called on appear.
//    • `refresh()`      — pull fresh transactions from the bank.
//    • `record(_:)`     — persist a manually logged transaction, then return
//      the merged ledger so manual entries mix cleanly with bank transfers.
//

import Foundation

// MARK: - Draft

/// A transaction the user is logging by hand. The amount is always a positive
/// magnitude; the direction carries the sign.
nonisolated struct StatsDraft: Sendable {
    let direction: TransferDirection
    let casinoId: String
    let amountCents: Int
    let date: Date
    let note: String
}

// MARK: - Protocol

nonisolated protocol StatsDataSource: Sendable {
    /// Fast read of whatever is already known, typically from a local cache.
    func loadLedger() async throws -> [StatsTransaction]

    /// Pull fresh transactions. Throws so the UI can surface a retry.
    func refresh() async throws -> [StatsTransaction]

    /// Persist a manual entry and return the merged ledger.
    func record(_ draft: StatsDraft) async throws -> [StatsTransaction]
}

// MARK: - Seed data

/// Demo ledger used until the real backend is connected: roughly six months of
/// believable deposits and payouts across every supported operator, generated
/// deterministically so the charts hold still between launches.
nonisolated enum StatsSeed {
    private struct Profile {
        let id: String
        let depositEvents: Int
        let typicalDepositDollars: Int
        /// Total paid back as a fraction of total deposited.
        let returnRate: Double
    }

    private static let profiles: [Profile] = [
        .init(id: "hard-rock", depositEvents: 9, typicalDepositDollars: 520, returnRate: 1.26),
        .init(id: "fanduel", depositEvents: 8, typicalDepositDollars: 340, returnRate: 0.88),
        .init(id: "draftkings", depositEvents: 6, typicalDepositDollars: 95, returnRate: 0.42),
        .init(id: "golden-nugget", depositEvents: 5, typicalDepositDollars: 330, returnRate: 0.95),
        .init(id: "betmgm", depositEvents: 4, typicalDepositDollars: 260, returnRate: 1.9),
        .init(id: "caesars", depositEvents: 4, typicalDepositDollars: 55, returnRate: 1.8),
        .init(id: "bet365", depositEvents: 4, typicalDepositDollars: 150, returnRate: 0.72),
        .init(id: "hollywood", depositEvents: 3, typicalDepositDollars: 60, returnRate: 2.1),
        .init(id: "betrivers", depositEvents: 3, typicalDepositDollars: 45, returnRate: 1.3),
        .init(id: "kalshi", depositEvents: 3, typicalDepositDollars: 30, returnRate: 1.1),
        .init(id: "polymarket", depositEvents: 3, typicalDepositDollars: 40, returnRate: 0.83),
        .init(id: "thescore-bet", depositEvents: 2, typicalDepositDollars: 25, returnRate: 0.0),
        .init(id: "bally", depositEvents: 2, typicalDepositDollars: 60, returnRate: 1.4),
        .init(id: "espn-bet", depositEvents: 2, typicalDepositDollars: 75, returnRate: 0.6),
        .init(id: "borgata", depositEvents: 2, typicalDepositDollars: 210, returnRate: 1.12),
        .init(id: "betway", depositEvents: 2, typicalDepositDollars: 50, returnRate: 0.9),
        .init(id: "pokerstars", depositEvents: 2, typicalDepositDollars: 65, returnRate: 1.05)
    ]

    static func ledger(now: Date = Date()) -> [StatsTransaction] {
        let day: TimeInterval = 86_400
        var result: [StatsTransaction] = []

        for (profileIndex, profile) in profiles.enumerated() {
            // Deterministic per-profile generator so the demo never changes shape.
            var state = UInt64(2_654_435_761 &+ UInt64(profileIndex) &* 9_791_911)
            func nextUnit() -> Double {
                state ^= state << 13
                state ^= state >> 7
                state ^= state << 17
                return Double(state % 10_000) / 10_000
            }

            for event in 0..<profile.depositEvents {
                let dollars = Double(profile.typicalDepositDollars) * (0.45 + nextUnit() * 1.3)
                let amountCents = max(500, Int(((dollars / 5).rounded() * 5) * 100))
                let depositDate = now.addingTimeInterval(-day * (0.3 + nextUnit() * 195))

                result.append(StatsTransaction(
                    id: "seed-\(profile.id)-d\(event)",
                    casinoId: profile.id,
                    direction: .deposit,
                    cents: -amountCents,
                    date: depositDate
                ))

                // Most deposits get a matching payout a day or two later.
                if profile.returnRate > 0, nextUnit() < 0.9 {
                    let payoutCents = Int(
                        (Double(amountCents) * profile.returnRate * (0.7 + nextUnit() * 0.6) / 100).rounded()
                    ) * 100
                    if payoutCents > 0 {
                        result.append(StatsTransaction(
                            id: "seed-\(profile.id)-w\(event)",
                            casinoId: profile.id,
                            direction: .withdrawal,
                            cents: payoutCents,
                            date: depositDate.addingTimeInterval(day * (0.5 + nextUnit() * 4))
                        ))
                    }
                }
            }
        }

        return result
    }
}

// MARK: - Seed implementation

nonisolated final class SeedStatsDataSource: StatsDataSource, @unchecked Sendable {
    private let lock = NSLock()
    private var ledger: [StatsTransaction]

    init(now: Date = Date()) {
        self.ledger = StatsSeed.ledger(now: now)
    }

    func loadLedger() async throws -> [StatsTransaction] {
        try await Task.sleep(for: .milliseconds(240))
        return lock.withLock { ledger }
    }

    func refresh() async throws -> [StatsTransaction] {
        // Latency the real client will also have; keeps the pull honest.
        try await Task.sleep(for: .milliseconds(850))
        return lock.withLock { ledger }
    }

    func record(_ draft: StatsDraft) async throws -> [StatsTransaction] {
        try await Task.sleep(for: .milliseconds(180))
        return lock.withLock {
            let transaction = StatsTransaction(
                id: "manual-\(UUID().uuidString)",
                casinoId: draft.casinoId,
                direction: draft.direction,
                cents: draft.direction == .deposit ? -draft.amountCents : draft.amountCents,
                date: draft.date,
                note: draft.note.isEmpty ? nil : draft.note
            )
            ledger.append(transaction)
            return ledger
        }
    }
}
