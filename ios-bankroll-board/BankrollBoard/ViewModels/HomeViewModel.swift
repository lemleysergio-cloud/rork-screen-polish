//
//  HomeViewModel.swift
//  BankrollBoard
//
//  Drives the Home screen: bankroll totals, chart series, and grouped activity.
//

import Foundation
import Observation

@Observable
final class HomeViewModel {
    // MARK: - State

    var timeframe: HomeTimeframe = .month {
        didSet {
            guard timeframe != oldValue else { return }
            rebuildSeries()
        }
    }

    var activityFilter: HomeActivityFilter = .all
    var isActivityExpanded = false
    var showingChartDetail = false
    /// Index into `series` while the user is scrubbing the chart.
    var scrubIndex: Int?

    private(set) var series: [BankrollPoint] = []
    private(set) var transfers: [HomeTransfer] = []

    private let now: Date

    init(now: Date = Date()) {
        self.now = now
        self.transfers = HomeSeed.transfers(now: now)
        rebuildSeries()
    }

    private func rebuildSeries() {
        scrubIndex = nil
        series = HomeSeed.series(for: timeframe, now: now)
    }

    // MARK: - Balances

    /// Settled balance only — pending transfers are excluded until the bank clears them.
    var settledCents: Int { HomeSeed.settledCents }

    var pendingTransfers: [HomeTransfer] {
        transfers.filter { $0.status == .pending }
    }

    /// Net effect on the bankroll once every pending transfer settles.
    var pendingNetCents: Int {
        pendingTransfers.reduce(0) { $0 + $1.cents }
    }

    var hasPending: Bool { !pendingTransfers.isEmpty }

    /// Balance projected forward, assuming all pending transfers settle as reported.
    var projectedCents: Int { settledCents + pendingNetCents }

    var periodDeltaCents: Int { HomeSeed.periodDeltaCents(for: timeframe) }

    var periodStartCents: Int { settledCents - periodDeltaCents }

    var periodPercent: String? {
        homePercent(delta: periodDeltaCents, from: periodStartCents)
    }

    /// Money earliest to settle first, so the soonest arrival leads the list.
    var pendingSortedBySettlement: [HomeTransfer] {
        pendingTransfers.sorted {
            ($0.expectedDate ?? .distantFuture) < ($1.expectedDate ?? .distantFuture)
        }
    }

    // MARK: - Scrubbing

    var scrubPoint: BankrollPoint? {
        guard let index = scrubIndex, series.indices.contains(index) else { return nil }
        return series[index]
    }

    var isScrubbing: Bool { scrubPoint != nil }

    /// Change from the window's opening value to the scrubbed point.
    var scrubDeltaCents: Int? {
        guard let point = scrubPoint, let first = series.first else { return nil }
        return point.cents - first.cents
    }

    func scrub(to index: Int?) {
        guard let index else {
            scrubIndex = nil
            return
        }
        let clamped = min(max(index, 0), max(series.count - 1, 0))
        guard clamped != scrubIndex else { return }
        scrubIndex = clamped
        Haptics.selection()
    }

    // MARK: - Activity

    private var filteredTransfers: [HomeTransfer] {
        switch activityFilter {
        case .all: transfers
        case .pending: transfers.filter { $0.status == .pending }
        case .deposits: transfers.filter { $0.direction == .deposit }
        case .withdrawals: transfers.filter { $0.direction == .withdrawal }
        }
    }

    /// Transfers grouped by day, newest first, collapsed to two days unless expanded.
    var activitySections: [HomeActivitySection] {
        let calendar = Calendar.current
        let sorted = filteredTransfers.sorted { $0.date > $1.date }

        var order: [Date] = []
        var buckets: [Date: [HomeTransfer]] = [:]
        for transfer in sorted {
            let day = calendar.startOfDay(for: transfer.date)
            if buckets[day] == nil {
                buckets[day] = []
                order.append(day)
            }
            buckets[day]?.append(transfer)
        }

        let sections = order.map { day in
            HomeActivitySection(
                id: ISO8601DateFormatter().string(from: day),
                title: homeDayTitle(day, now: now),
                transfers: buckets[day] ?? []
            )
        }

        guard !isActivityExpanded else { return sections }
        return Array(sections.prefix(2))
    }

    var hiddenActivityCount: Int {
        let shown = activitySections.reduce(0) { $0 + $1.transfers.count }
        return max(filteredTransfers.count - shown, 0)
    }

    var filterCounts: [HomeActivityFilter: Int] {
        [
            .all: transfers.count,
            .pending: transfers.filter { $0.status == .pending }.count,
            .deposits: transfers.filter { $0.direction == .deposit }.count,
            .withdrawals: transfers.filter { $0.direction == .withdrawal }.count
        ]
    }

    func select(filter: HomeActivityFilter) {
        guard filter != activityFilter else { return }
        Haptics.selection()
        activityFilter = filter
        isActivityExpanded = false
    }

    func select(timeframe newValue: HomeTimeframe) {
        guard newValue != timeframe else { return }
        Haptics.selection()
        timeframe = newValue
    }

    func toggleActivityExpansion() {
        Haptics.tap()
        isActivityExpanded.toggle()
    }
}
