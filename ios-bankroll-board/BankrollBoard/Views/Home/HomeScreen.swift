//
//  HomeScreen.swift
//  BankrollBoard
//
//  Home: net bankroll, money still in flight from the bank, the bankroll
//  curve over time, and recent transfer activity grouped by day.
//

import SwiftUI

struct HomeScreen: View {
    @State private var model = HomeViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [JourneyPalette.canvasDeep, JourneyPalette.canvas, Color(rgb: 0x132F20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HomeSyncBar(
                        caption: model.lastSyncedCaption,
                        isSyncing: model.syncStatus.isSyncing,
                        onRefresh: { Task { await model.sync(trigger: .manual) } }
                    )
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 4)

                    HomeSyncBanner(
                        phase: model.syncStatus.phase,
                        onRetry: { Task { await model.sync(trigger: .manual) } },
                        onDismiss: { model.dismissSyncBanner() }
                    )
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 8)

                    if !model.accountsNeedingAttention.isEmpty {
                        HomeReconnectCard(
                            accounts: model.accountsNeedingAttention,
                            onReconnect: { account in
                                Task { await model.reconnect(account) }
                            }
                        )
                        .padding(.horizontal, BBTheme.screenMargin)
                        .padding(.top, 12)
                    }

                    hero
                        .padding(.horizontal, BBTheme.screenMargin)
                        .padding(.top, 14)

                    if model.hasPending {
                        pendingCard
                            .padding(.horizontal, BBTheme.screenMargin)
                            .padding(.top, 18)
                    }

                    rule.padding(.top, 24)

                    chartSection
                        .padding(.top, 24)

                    rule.padding(.top, 26)

                    activitySection
                        .padding(.top, 26)
                }
                // Clears the floating tab bar so the last row is never hidden.
                .padding(.bottom, 132)
                .animation(.easeInOut(duration: 0.25), value: model.syncStatus.phase)
                .animation(.easeInOut(duration: 0.25), value: model.settledCents)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await model.sync(trigger: .pullToRefresh)
            }
            .accessibilityIdentifier("home.page")
            .redacted(reason: model.isLoading ? .placeholder : [])
        }
        .task {
            await model.onAppear()
        }
        .fullScreenCover(isPresented: $model.showingChartDetail) {
            HomeChartDetailView(model: model)
        }
        .sheet(item: $model.pendingReauth) { request in
            HomeReauthSheet(
                request: request,
                onFinished: { Task { await model.completeReauth() } }
            )
        }
    }

    private var rule: some View {
        Rectangle()
            .fill(BBTheme.hairline.opacity(0.55))
            .frame(height: 1)
            .padding(.horizontal, BBTheme.screenMargin)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR OVERVIEW")
                .bbEyebrowStyle()

            Text("The Bank")
                .font(BBTheme.headline(40))
                .foregroundStyle(BBTheme.ink)
                .padding(.top, 6)

            balanceRow
                .padding(.top, 16)

            Text(balanceCaption)
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
                .padding(.top, 10)

            deltaRow
                .padding(.top, 12)
        }
    }

    /// The headline holds the settled balance even while scrubbing; the chart's
    /// own callout reports the inspected point, so the anchor never moves.
    private var balanceRow: some View {
        let parts = homeBalanceParts(cents: model.settledCents)
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(parts.dollars)
                .font(BBTheme.money(48))
                .foregroundStyle(BBTheme.positive)
            Text(parts.cents)
                .font(BBTheme.money(32))
                .foregroundStyle(BBTheme.positive.opacity(0.85))
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Net bankroll \(homeMoney(cents: model.settledCents, showsPlus: false)), settled")
    }

    private var balanceCaption: String {
        model.hasPending ? "Settled net bankroll · All time" : "Net bankroll · All time"
    }

    private var deltaRow: some View {
        let delta = model.periodDeltaCents
        let isNegative = delta < 0
        return HStack(spacing: 7) {
            Image(systemName: isNegative ? "arrowtriangle.down.fill" : "arrowtriangle.up.fill")
                .font(.system(size: 9))
            Text(homeMoney(cents: delta))
                .monospacedDigit()
            if let percent = model.periodPercent {
                Text("(\(percent))")
                    .monospacedDigit()
            }
            Text(model.timeframe.deltaCaption)
                .foregroundStyle(BBTheme.inkMuted)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(isNegative ? Color(rgb: 0xE2928A) : BBTheme.positive)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Pending

    /// Pending transfers are authorized by the bank but not settled, so they are
    /// excluded from the headline balance and surfaced here instead.
    private var pendingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BBTheme.gold)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(model.pendingTransfers.count) transfer\(model.pendingTransfers.count == 1 ? "" : "s") pending at your bank")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BBTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Not counted in your balance until the bank settles them.")
                        .font(.system(size: 11))
                        .foregroundStyle(BBTheme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Divider()
                .overlay(BBTheme.gold.opacity(0.18))
                .padding(.vertical, 12)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NET WHEN SETTLED")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(0.8)
                        .foregroundStyle(BBTheme.inkMuted)
                    Text(homeMoney(cents: model.pendingNetCents))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(model.pendingNetCents < 0 ? Color(rgb: 0xE2928A) : BBTheme.positive)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("PROJECTED BALANCE")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(0.8)
                        .foregroundStyle(BBTheme.inkMuted)
                    Text(homeMoney(cents: model.projectedCents, showsPlus: false))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(BBTheme.ink)
                        .monospacedDigit()
                }
            }

            Button {
                model.select(filter: .pending)
                if !model.isActivityExpanded { model.isActivityExpanded = true }
            } label: {
                HStack(spacing: 5) {
                    Text("Review pending")
                        .font(.system(size: 12, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(BBTheme.gold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(BBPressStyle())
        }
        .padding(.horizontal, 15)
        .padding(.top, 14)
        .padding(.bottom, 2)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(BBTheme.gold.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(BBTheme.gold.opacity(0.26), lineWidth: 1)
                }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Bankroll over time")
                    .font(BBTheme.headline(25))
                    .foregroundStyle(BBTheme.ink)

                Spacer(minLength: 0)

                Button {
                    Haptics.tap()
                    model.showingChartDetail = true
                } label: {
                    HStack(spacing: 5) {
                        Text("Expand")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(BBTheme.gold)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(BBPressStyle())
                .accessibilityLabel("Expand chart to full screen")
            }
            .padding(.horizontal, BBTheme.screenMargin)

            Text("Cumulative net transfers. Touch and drag the chart to inspect any point.")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, BBTheme.screenMargin)
                .padding(.top, 2)

            HomeBankrollChart(
                points: model.series,
                timeframe: model.timeframe,
                scrubIndex: model.scrubIndex,
                onScrub: { model.scrub(to: $0) }
            )
            .padding(.horizontal, BBTheme.screenMargin)
            .padding(.top, 16)

            HomeTimeframeBar(
                selection: model.timeframe,
                onSelect: { model.select(timeframe: $0) }
            )
            .padding(.horizontal, BBTheme.screenMargin)
            .padding(.top, 18)
        }
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Recent activity")
                    .font(BBTheme.headline(25))
                    .foregroundStyle(BBTheme.ink)

                Spacer(minLength: 0)

                if model.hiddenActivityCount > 0 || model.isActivityExpanded {
                    Button {
                        model.toggleActivityExpansion()
                    } label: {
                        Text(model.isActivityExpanded ? "Show less" : "See all")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BBTheme.gold)
                            .frame(height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(BBPressStyle())
                }
            }
            .padding(.horizontal, BBTheme.screenMargin)

            filterRow
                .padding(.top, 4)

            if model.activitySections.isEmpty {
                emptyActivity
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 18)
            } else {
                ForEach(model.activitySections) { section in
                    HomeActivityDaySection(section: section)
                        .padding(.top, 18)
                }

                if model.hiddenActivityCount > 0 {
                    Button {
                        model.toggleActivityExpansion()
                    } label: {
                        Text("Show \(model.hiddenActivityCount) earlier transfer\(model.hiddenActivityCount == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BBTheme.gold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(BBTheme.hairline, lineWidth: 1)
                            }
                    }
                    .buttonStyle(BBPressStyle())
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 20)
                }
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(HomeActivityFilter.allCases) { filter in
                    let count = model.filterCounts[filter] ?? 0
                    HomeFilterChip(
                        title: filter.title,
                        count: count,
                        isSelected: model.activityFilter == filter,
                        isAccented: filter == .pending && count > 0
                    ) {
                        model.select(filter: filter)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, BBTheme.screenMargin, for: .scrollContent)
    }

    private var emptyActivity: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nothing here yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BBTheme.ink)
            Text("No \(model.activityFilter.title.lowercased()) transfers to show. Try another filter.")
                .font(.system(size: 12))
                .foregroundStyle(BBTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(BBTheme.hairline.opacity(0.7), lineWidth: 1)
        }
    }
}

// MARK: - Day section

/// One day of transfers under a sticky-feeling date heading with the day's net.
struct HomeActivityDaySection: View {
    let section: HomeActivitySection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(section.title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.1)
                    .foregroundStyle(BBTheme.inkMuted)

                Spacer(minLength: 8)

                Text(homeMoney(cents: section.netCents))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(section.netCents < 0 ? Color(rgb: 0xE2928A) : BBTheme.positive)
                    .monospacedDigit()
            }
            .padding(.horizontal, BBTheme.screenMargin)
            .padding(.bottom, 2)

            ForEach(Array(section.transfers.enumerated()), id: \.element.id) { index, transfer in
                VStack(spacing: 0) {
                    if index > 0 {
                        Rectangle()
                            .fill(BBTheme.hairline.opacity(0.4))
                            .frame(height: 1)
                    }
                    HomeActivityRow(transfer: transfer)
                }
                .padding(.horizontal, BBTheme.screenMargin)
            }
        }
    }
}

// MARK: - Controls

/// Six-way segmented control for the chart window.
struct HomeTimeframeBar: View {
    let selection: HomeTimeframe
    let onSelect: (HomeTimeframe) -> Void

    var body: some View {
        HStack(spacing: 3) {
            ForEach(HomeTimeframe.allCases) { timeframe in
                let isActive = timeframe == selection
                Button {
                    onSelect(timeframe)
                } label: {
                    Text(timeframe.short)
                        .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? BBTheme.goldBright : BBTheme.inkMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background {
                            if isActive {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(BBTheme.gold.opacity(0.14))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(BBTheme.gold.opacity(0.3), lineWidth: 1)
                                    }
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(BBPressStyle())
                .accessibilityLabel(timeframe.long)
                .accessibilityAddTraits(isActive ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.black.opacity(0.16))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(BBTheme.hairline.opacity(0.6), lineWidth: 1)
                }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: selection)
    }
}

/// Pill filter for the activity list, with a count badge.
struct HomeFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    var isAccented: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isAccented {
                    Circle()
                        .fill(BBTheme.gold)
                        .frame(width: 5, height: 5)
                }
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Text("\(count)")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .opacity(0.7)
            }
            .foregroundStyle(isSelected ? JourneyPalette.canvasDeep : BBTheme.inkMuted)
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background {
                Capsule()
                    .fill(isSelected ? BBTheme.gold : Color.white.opacity(0.05))
                    .overlay {
                        Capsule()
                            .stroke(
                                isSelected ? Color.clear : BBTheme.hairline.opacity(0.7),
                                lineWidth: 1
                            )
                    }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(BBPressStyle())
        .accessibilityLabel("\(title), \(count) transfers")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    HomeScreen()
}
