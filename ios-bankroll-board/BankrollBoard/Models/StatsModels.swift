//
//  StatsModels.swift
//  BankrollBoard
//
//  Stats data model: the transfer ledger, windowed flow buckets, per-platform
//  results, and the plain-language summary figures. Deposits are money sent
//  out of your bank; withdrawals are money that came back.
//

import Foundation
import SwiftUI

// MARK: - Palette

/// Colors specific to the Stats screen's two directions of money.
nonisolated enum StatsPalette {
    /// Money coming back to the bank (withdrawals) — sage, matching the web build.
    static let sage = Color(rgb: 0x9FBFA8)
    /// Money leaving for apps (deposits) — the brand gold.
    static let sent = BBTheme.gold
    /// A window where more left than returned.
    static let loss = Color(rgb: 0xE2928A)
}

// MARK: - Transaction

/// One movement of money in the stats ledger.
///
/// `cents` is signed like the rest of the app: deposits (bank → app) are
/// negative, withdrawals (app → bank) are positive.
nonisolated struct StatsTransaction: Identifiable, Hashable, Sendable {
    let id: String
    let casinoId: String
    let direction: TransferDirection
    let cents: Int
    let date: Date
    let note: String?

    init(
        id: String,
        casinoId: String,
        direction: TransferDirection,
        cents: Int,
        date: Date,
        note: String? = nil
    ) {
        self.id = id
        self.casinoId = casinoId
        self.direction = direction
        self.cents = cents
        self.date = date
        self.note = note
    }

    /// Row title, e.g. "Hard Rock Digital Withdrawal".
    var title: String {
        "\(HomeCasino.name(for: casinoId)) \(direction.verb)"
    }
}

// MARK: - Window summary

/// Totals for the selected window, in plain-language terms.
nonisolated struct StatsSummary: Hashable, Sendable {
    /// Money that left the bank, as a positive magnitude.
    let sentCents: Int
    /// Money that came back, as a positive magnitude.
    let returnedCents: Int

    var netCents: Int { returnedCents - sentCents }

    /// Cents that came back per $100 sent out, e.g. 820 == "$8.20".
    var returnedPerHundredCents: Int? {
        guard sentCents > 0 else { return nil }
        return Int((Double(returnedCents) / Double(sentCents) * 100).rounded())
    }

    var directionCaption: String {
        if sentCents == 0 && returnedCents == 0 { return "Nothing moved in this window yet." }
        if netCents > 0 { return "More came back than went out." }
        if netCents < 0 { return "More went out than came back." }
        return "Even between what went out and what came back."
    }
}

// MARK: - Flow buckets

/// One column of the money-flow chart: a slice of the window with its totals.
nonisolated struct StatsBucket: Identifiable, Hashable, Sendable {
    let id: Int
    let label: String
    let start: Date
    let end: Date
    var sentCents: Int
    var returnedCents: Int

    var netCents: Int { returnedCents - sentCents }
    var isEmpty: Bool { sentCents == 0 && returnedCents == 0 }
}

/// Friendly name for the selected window, used on the summary card.
nonisolated func statsWindowLabel(for timeframe: HomeTimeframe) -> String {
    switch timeframe {
    case .day: "Today"
    case .week: "Past 7 days"
    case .month: "Past 30 days"
    case .ytd: "This year"
    case .year: "Past 12 months"
    case .all: "All time"
    }
}

/// Splits the window into labelled slices and totals the ledger inside each.
nonisolated func statsBuckets(
    for timeframe: HomeTimeframe,
    transactions: [StatsTransaction],
    now: Date
) -> [StatsBucket] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: now)

    func daySpans(count: Int, daysEach: Int) -> [(start: Date, end: Date)] {
        let windowStart = calendar.date(byAdding: .day, value: -(count * daysEach - 1), to: today) ?? today
        return (0..<count).compactMap { index in
            guard let start = calendar.date(byAdding: .day, value: index * daysEach, to: windowStart),
                  let end = calendar.date(byAdding: .day, value: daysEach, to: start) else { return nil }
            return (start, end)
        }
    }

    func monthSpans(count: Int) -> (spans: [(start: Date, end: Date)], labels: [String]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let first = calendar.date(byAdding: .month, value: -(count - 1), to: today) ?? today
        var spans: [(start: Date, end: Date)] = []
        var labels: [String] = []
        for index in 0..<count {
            guard let start = calendar.date(byAdding: .month, value: index, to: first),
                  let end = calendar.date(byAdding: .month, value: 1, to: start) else { continue }
            spans.append((start, end))
            labels.append(formatter.string(from: start))
        }
        return (spans, labels)
    }

    let spans: [(start: Date, end: Date)]
    let labels: [String]

    switch timeframe {
    case .day:
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var built: [(start: Date, end: Date)] = []
        var builtLabels: [String] = []
        for index in 0..<8 {
            guard let start = calendar.date(byAdding: .hour, value: index * 3, to: today),
                  let end = calendar.date(byAdding: .hour, value: 3, to: start) else { continue }
            built.append((start, end))
            builtLabels.append(formatter.string(from: start))
        }
        spans = built
        labels = builtLabels

    case .week:
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let built = daySpans(count: 7, daysEach: 1)
        spans = built.map { ($0.start, $0.end) }
        labels = built.map { formatter.string(from: $0.start) }

    case .month:
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let built = daySpans(count: 10, daysEach: 3)
        spans = built.map { ($0.start, $0.end) }
        labels = built.map { formatter.string(from: $0.start) }

    case .ytd:
        let monthIndex = calendar.component(.month, from: today)
        let built = monthSpans(count: max(1, monthIndex))
        spans = built.spans
        labels = built.labels

    case .year:
        let built = monthSpans(count: 12)
        spans = built.spans
        labels = built.labels

    case .all:
        let built = monthSpans(count: 6)
        spans = built.spans
        labels = built.labels
    }

    guard spans.count == labels.count, !spans.isEmpty else { return [] }

    return spans.enumerated().map { index, span in
        var sent = 0
        var returned = 0
        for transaction in transactions where transaction.date >= span.start && transaction.date < span.end {
            if transaction.direction == .deposit {
                sent += abs(transaction.cents)
            } else {
                returned += abs(transaction.cents)
            }
        }
        return StatsBucket(
            id: index,
            label: labels[index],
            start: span.start,
            end: span.end,
            sentCents: sent,
            returnedCents: returned
        )
    }
}

// MARK: - Platforms

/// Money in and out for one operator over the window.
nonisolated struct StatsPlatformResult: Identifiable, Hashable, Sendable {
    let casinoId: String
    var sentCents: Int
    var returnedCents: Int

    var netCents: Int { returnedCents - sentCents }
    var id: String { casinoId }
}

/// Aggregates the ledger per platform, best net result first.
nonisolated func statsPlatformResults(
    from transactions: [StatsTransaction]
) -> [StatsPlatformResult] {
    var sent: [String: Int] = [:]
    var returned: [String: Int] = [:]
    for transaction in transactions {
        if transaction.direction == .deposit {
            sent[transaction.casinoId, default: 0] += abs(transaction.cents)
        } else {
            returned[transaction.casinoId, default: 0] += abs(transaction.cents)
        }
    }
    let ids = Set(sent.keys).union(returned.keys)
    return ids
        .map { StatsPlatformResult(casinoId: $0, sentCents: sent[$0] ?? 0, returnedCents: returned[$0] ?? 0) }
        .sorted { $0.netCents > $1.netCents }
}

// MARK: - Activity grouping

/// One day of ledger activity for the recent-transactions list.
nonisolated struct StatsActivityGroup: Identifiable, Hashable, Sendable {
    let id: Date
    let items: [StatsTransaction]

    var title: String { homeDayTitle(id) }
    var netCents: Int { items.reduce(0) { $0 + $1.cents } }
}

/// Groups a ledger by calendar day, newest first.
nonisolated func statsActivityGroups(
    from transactions: [StatsTransaction],
    now: Date
) -> [StatsActivityGroup] {
    let calendar = Calendar.current
    let grouped = Dictionary(grouping: transactions) { calendar.startOfDay(for: $0.date) }
    return grouped
        .map { day, items in
            StatsActivityGroup(
                id: day,
                items: items.sorted { $0.date > $1.date }
            )
        }
        .sorted { $0.id > $1.id }
}
