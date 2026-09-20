//
//  HomeViewModel.swift
//  BankrollBoard
//
//  Drives the Home screen: bankroll totals, chart series, grouped activity, and
//  the Plaid refresh lifecycle.
//
//  All data arrives through `HomeDataSource`, so connecting the real backend is
//  a matter of injecting a different implementation — see HomeDataSource.swift.
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
    private(set) var snapshot: HomeSnapshot = .empty
    private(set) var syncStatus: HomeSyncStatus = .idle
    /// True until the first snapshot lands, so Home can show skeletons.
    private(set) var isLoading = true

    /// Link token awaiting presentation after the user taps Reconnect.
    var pendingReauth: ReauthRequest?

    nonisolated struct ReauthRequest: Identifiable, Equatable, Sendable {
        let id: String
        let institutionName: String
        let linkToken: String
    }

    private let dataSource: HomeDataSource
    private let now: Date
    private var syncTask: Task<Void, Never>?

    init(dataSource: HomeDataSource = SeedHomeDataSource(), now: Date = Date()) {
        self.dataSource = dataSource
        self.now = now
        rebuildSeries()
    }

    var transfers: [HomeTransfer] { snapshot.transfers }

    // MARK: - Loading & syncing

    /// First load: serve whatever is cached, then quietly refresh behind it.
    func onAppear() async {
        guard isLoading else { return }
        do {
            let loaded = try await dataSource.loadSnapshot()
            apply(loaded)
            syncStatus.lastSyncedAt = loaded.generatedAt
        } catch {
            recordFailure(error, trigger: .initialLoad)
        }
        isLoading = false
    }

    /// Pull fresh transactions from the bank.
    ///
    /// Re-entrant taps are ignored rather than queued — a second `/transactions/sync`
    /// while one is in flight only duplicates work.
    func sync(trigger: HomeSyncTrigger = .manual) async {
        guard !syncStatus.isSyncing else { return }

        if trigger.isUserInitiated {
            Haptics.tap()
        }
        syncStatus.trigger = trigger
        syncStatus.phase = .syncing

        do {
            let fresh = try await dataSource.refresh(trigger: trigger)
            let summary = changeSummary(from: snapshot, to: fresh)
            apply(fresh)
            syncStatus.lastSyncedAt = fresh.generatedAt
            syncStatus.phase = .succeeded(
                newTransfers: summary.added,
                newlySettled: summary.settled
            )
            if trigger.isUserInitiated {
                Haptics.success()
            }
            await clearBanner(after: .seconds(3))
        } catch {
            recordFailure(error, trigger: trigger)
            if trigger.isUserInitiated {
                Haptics.warning()
            }
        }
    }

    /// Dismiss a success or failure banner without touching an in-flight sync.
    func dismissSyncBanner() {
        guard !syncStatus.isSyncing else { return }
        syncStatus.phase = .idle
    }

    /// Opens Plaid Link in update mode for a connection that needs repair.
    func reconnect(_ account: LinkedAccount) async {
        Haptics.tap()
        do {
            let token = try await dataSource.reauthToken(for: account.id)
            pendingReauth = ReauthRequest(
                id: account.id,
                institutionName: account.institutionName,
                linkToken: token
            )
        } catch {
            syncStatus.phase = .failed(
                message: "Couldn't start reconnecting \(account.institutionName).",
                isRecoverable: true
            )
        }
    }

    /// Called once Plaid Link reports success, to pick up the repaired account.
    func completeReauth() async {
        pendingReauth = nil
        await sync(trigger: .manual)
    }

    private func apply(_ new: HomeSnapshot) {
        snapshot = new
        rebuildSeries()
    }

    private func recordFailure(_ error: Error, trigger: HomeSyncTrigger) {
        let dataError = error as? HomeDataError ?? .server("Couldn't reach your bank. Pull to try again.")
        syncStatus.phase = .failed(
            message: dataError.errorDescription ?? "Something went wrong.",
            isRecoverable: dataError.isRecoverable
        )
        syncStatus.trigger = trigger
    }

    /// Counts what a refresh actually changed, so the banner can be specific
    /// instead of saying "Updated" every time.
    private func changeSummary(
        from old: HomeSnapshot,
        to new: HomeSnapshot
    ) -> (added: Int, settled: Int) {
        let oldIds = Set(old.transfers.map(\.id))
        let added = new.transfers.filter { !oldIds.contains($0.id) }.count

        let oldPending = Set(
            old.transfers.filter { $0.status == .pending }.map(\.id)
        )
        let settled = new.transfers.filter {
            $0.status == .settled && oldPending.contains($0.id)
        }.count

        return (added, settled)
    }

    private func clearBanner(after duration: Duration) async {
        syncTask?.cancel()
        let task = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            guard let self, !self.syncStatus.isSyncing else { return }
            if case .succeeded = self.syncStatus.phase {
                self.syncStatus.phase = .idle
            }
        }
        syncTask = task
        await task.value
    }

    private func rebuildSeries() {
        scrubIndex = nil
        series = HomeSeed.series(
            for: timeframe,
            endingAt: snapshot == .empty ? HomeSeed.settledCents : snapshot.settledCents,
            now: now
        )
    }

    // MARK: - Balances

    /// Settled balance only — pending transfers are excluded until the bank clears them.
    var settledCents: Int {
        snapshot == .empty ? HomeSeed.settledCents : snapshot.settledCents
    }

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

    var periodDeltaCents: Int {
        snapshot == .empty
            ? HomeSeed.periodDeltaCents(for: timeframe)
            : snapshot.delta(for: timeframe)
    }

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

    // MARK: - Accounts

    var linkedAccounts: [LinkedAccount] { snapshot.accounts }

    var accountsNeedingAttention: [LinkedAccount] { snapshot.accountsNeedingAttention }

    var lastSyncedCaption: String {
        homeRelativeTime(syncStatus.lastSyncedAt, now: Date())
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
