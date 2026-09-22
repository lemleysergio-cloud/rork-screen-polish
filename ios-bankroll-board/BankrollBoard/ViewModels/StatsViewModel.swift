//
//  StatsViewModel.swift
//  BankrollBoard
//
//  Drives the Stats screen: windowed totals, flow buckets, per-platform
//  results, and the recent-transactions list.
//
//  All data arrives through `StatsDataSource`, so connecting the real backend
//  is a matter of injecting a different implementation — see StatsDataSource.swift.
//

import Foundation
import Observation

@Observable
final class StatsViewModel {
    // MARK: - State

    var timeframe: HomeTimeframe = .ytd
    /// Index of the flow-chart column the user tapped, if any.
    var selectedBucket: Int?
    var showingAddSheet = false
    var isActivityExpanded = false

    private(set) var transactions: [StatsTransaction] = []
    /// True until the first ledger lands, so the screen can show skeletons.
    private(set) var isLoading = true

    private let dataSource: StatsDataSource
    private let now: Date

    init(dataSource: StatsDataSource = SeedStatsDataSource(), now: Date = Date()) {
        self.dataSource = dataSource
        self.now = now
    }

    // MARK: - Loading

    func onAppear() async {
        guard isLoading else { return }
        do {
            transactions = try await dataSource.loadLedger()
        } catch {
            // Seed data only fails on programmer error; a real source would
            // surface a retry banner here, mirroring Home.
        }
        isLoading = false
    }

    /// Pull-to-refresh.
    func refresh() async {
        do {
            let fresh = try await dataSource.refresh()
            transactions = fresh
            Haptics.success()
        } catch {
            Haptics.warning()
        }
    }

    // MARK: - Selection

    func select(timeframe: HomeTimeframe) {
        guard timeframe != self.timeframe else { return }
        Haptics.selection()
        self.timeframe = timeframe
        selectedBucket = nil
    }

    /// Tapping a selected column again dismisses its readout.
    func select(bucket: Int?) {
        Haptics.selection()
        selectedBucket = (bucket == selectedBucket) ? nil : bucket
    }

    func toggleActivityExpansion() {
        Haptics.tap()
        isActivityExpanded.toggle()
    }

    // MARK: - Derived data

    private var windowStart: Date {
        let calendar = Calendar.current
        switch timeframe {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        case .ytd:
            return calendar.date(from: DateComponents(year: calendar.component(.year, from: now))) ?? now
        case .month, .year, .all:
            return now.addingTimeInterval(-timeframe.span)
        }
    }

    /// Everything the ledger holds inside the selected window.
    var windowTransactions: [StatsTransaction] {
        transactions.filter { $0.date >= windowStart }
    }

    var summary: StatsSummary {
        var sent = 0
        var returned = 0
        for transaction in windowTransactions {
            if transaction.direction == .deposit {
                sent += abs(transaction.cents)
            } else {
                returned += abs(transaction.cents)
            }
        }
        return StatsSummary(sentCents: sent, returnedCents: returned)
    }

    var buckets: [StatsBucket] {
        statsBuckets(for: timeframe, transactions: transactions, now: now)
    }

    var selectedBucketDetail: StatsBucket? {
        guard let selectedBucket, buckets.indices.contains(selectedBucket) else { return nil }
        return buckets[selectedBucket]
    }

    var platforms: [StatsPlatformResult] {
        statsPlatformResults(from: windowTransactions)
    }

    /// Widest absolute net across platforms, for scaling the result bars.
    var maxAbsPlatformNet: Int {
        platforms.map { abs($0.netCents) }.max() ?? 0
    }

    var activityGroups: [StatsActivityGroup] {
        statsActivityGroups(from: windowTransactions, now: now)
    }

    /// The list capped to a digestible run of rows until the user asks for more.
    var visibleGroups: [StatsActivityGroup] {
        guard !isActivityExpanded else { return activityGroups }
        var groups: [StatsActivityGroup] = []
        var shown = 0
        for group in activityGroups {
            if shown >= 12 { break }
            let room = 12 - shown
            if group.items.count <= room {
                groups.append(group)
                shown += group.items.count
            } else {
                groups.append(StatsActivityGroup(id: group.id, items: Array(group.items.prefix(room))))
                shown += room
            }
        }
        return groups
    }

    var hiddenTransactionCount: Int {
        let visible = visibleGroups.reduce(0) { $0 + $1.items.count }
        return max(0, activityGroups.reduce(0) { $0 + $1.items.count } - visible)
    }

    // MARK: - Adding

    /// Persists a hand-logged transaction through the seam, so manual entries
    /// and bank transfers will mix cleanly once the backend lands.
    func add(_ draft: StatsDraft) async {
        do {
            transactions = try await dataSource.record(draft)
            Haptics.success()
        } catch {
            Haptics.warning()
        }
    }
}
