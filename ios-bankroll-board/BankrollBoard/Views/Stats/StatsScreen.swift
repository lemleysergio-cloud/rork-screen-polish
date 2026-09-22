//
//  StatsScreen.swift
//  BankrollBoard
//
//  Stats: money out and money back in plain language — a window summary,
//  a tappable flow chart, the split ring, per-platform results, and recent
//  transactions with a way to log one by hand.
//

import SwiftUI

struct StatsScreen: View {
    @State private var model = StatsViewModel()

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
                    header
                        .padding(.horizontal, BBTheme.screenMargin)
                        .padding(.top, 8)

                    HomeTimeframeBar(
                        selection: model.timeframe,
                        onSelect: { model.select(timeframe: $0) }
                    )
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 16)

                    summaryCard
                        .padding(.horizontal, BBTheme.screenMargin)
                        .padding(.top, 18)

                    rule.padding(.top, 24)

                    flowSection
                        .padding(.top, 24)

                    rule.padding(.top, 26)

                    ratioSection
                        .padding(.top, 26)

                    rule.padding(.top, 26)

                    platformSection
                        .padding(.top, 26)

                    rule.padding(.top, 26)

                    transactionsSection
                        .padding(.top, 26)
                }
                // Clears the floating tab bar so the last row is never hidden.
                .padding(.bottom, 132)
                .animation(.easeInOut(duration: 0.25), value: model.timeframe)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await model.refresh()
            }
            .accessibilityIdentifier("stats.page")
            .redacted(reason: model.isLoading ? .placeholder : [])
        }
        .task {
            await model.onAppear()
        }
        .sheet(isPresented: $model.showingAddSheet) {
            StatsAddSheet(model: model)
        }
    }

    private var rule: some View {
        Rectangle()
            .fill(BBTheme.hairline.opacity(0.55))
            .frame(height: 1)
            .padding(.horizontal, BBTheme.screenMargin)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR MONEY, IN PERSPECTIVE")
                .bbEyebrowStyle()

            Text("Your Stats")
                .font(BBTheme.headline(40))
                .foregroundStyle(BBTheme.ink)
                .padding(.top, 6)

            Text("A plain view of what goes to the apps — and what comes back.")
                .font(BBTheme.body)
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        let summary = model.summary
        let parts = homeBalanceParts(cents: abs(summary.netCents))
        let isNegative = summary.netCents < 0

        return VStack(alignment: .leading, spacing: 0) {
            Text("CAME BACK, MINUS WHAT WENT OUT · \(statsWindowLabel(for: model.timeframe).uppercased())")
                .font(.system(size: 9, weight: .bold))
                .kerning(1)
                .foregroundStyle(BBTheme.inkMuted)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(isNegative ? "−" : "+")
                    .font(BBTheme.money(40))
                Text(parts.dollars)
                    .font(BBTheme.money(44))
                Text(parts.cents)
                    .font(BBTheme.money(28))
            }
            .foregroundStyle(isNegative ? StatsPalette.loss : BBTheme.positive)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.top, 10)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Net for \(statsWindowLabel(for: model.timeframe)): \(homeMoney(cents: summary.netCents))")

            Text(summary.directionCaption)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BBTheme.inkMuted)
                .padding(.top, 6)

            Divider()
                .overlay(BBTheme.hairline.opacity(0.55))
                .padding(.vertical, 15)

            HStack(alignment: .center, spacing: 16) {
                summaryTile(
                    label: "SENT TO APPS",
                    cents: summary.sentCents,
                    caption: "Bank → Apps",
                    color: StatsPalette.sent
                )

                Rectangle()
                    .fill(BBTheme.hairline.opacity(0.55))
                    .frame(width: 1, height: 52)

                summaryTile(
                    label: "CAME BACK",
                    cents: summary.returnedCents,
                    caption: "Apps → Bank",
                    color: StatsPalette.sage
                )
            }

            if let perHundred = summary.returnedPerHundredCents {
                HStack(spacing: 7) {
                    Circle()
                        .fill(BBTheme.gold)
                        .frame(width: 4, height: 4)
                    Text("For every $100 you sent out, \(homeMoney(cents: perHundred, showsPlus: false)) came back.")
                        .font(.system(size: 11))
                        .foregroundStyle(BBTheme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 15)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: BBTheme.cardRadius, style: .continuous)
                .fill(BBTheme.surface.opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: BBTheme.cardRadius, style: .continuous)
                        .stroke(BBTheme.hairline.opacity(0.55), lineWidth: 1)
                }
        }
    }

    private func summaryTile(label: String, cents: Int, caption: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .kerning(0.9)
                .foregroundStyle(BBTheme.inkMuted)

            Text(homeMoney(cents: cents, showsPlus: false))
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(caption)
                .font(.system(size: 10))
                .foregroundStyle(BBTheme.inkMuted.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Flow chart

    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Money flow over time")
                .font(BBTheme.headline(25))
                .foregroundStyle(BBTheme.ink)

            Text("Each pair of bars is a slice of the window — tap one to inspect it.")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)

            HStack(spacing: 16) {
                legendDot(color: StatsPalette.sent, title: "Went to apps")
                legendDot(color: StatsPalette.sage, title: "Came back")
            }
            .padding(.top, 12)

            StatsFlowChart(
                buckets: model.buckets,
                selectedIndex: model.selectedBucket,
                onSelect: { model.select(bucket: $0) }
            )
            .padding(.top, 14)

            StatsBucketReadout(
                bucket: model.selectedBucketDetail,
                windowLabel: statsWindowLabel(for: model.timeframe)
            )
            .padding(.top, 10)
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }

    private func legendDot(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 9, height: 9)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Split

    private var ratioSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("The split")
                .font(BBTheme.headline(25))
                .foregroundStyle(BBTheme.ink)

            Text("How the money you moved divided up.")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
                .padding(.top, 3)

            let summary = model.summary
            StatsRatioView(
                sentCents: summary.sentCents,
                returnedCents: summary.returnedCents
            )
            .padding(.top, 14)
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }

    // MARK: - Platforms

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("By platform")
                .font(BBTheme.headline(25))
                .foregroundStyle(BBTheme.ink)

            Text("Which apps gave money back — and which kept it. Best net first.")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)

            if model.platforms.isEmpty {
                Text("No platform activity in this window.")
                    .font(.system(size: 12))
                    .foregroundStyle(BBTheme.inkMuted)
                    .padding(.top, 16)
            } else {
                ForEach(Array(model.platforms.enumerated()), id: \.element.id) { index, result in
                    StatsPlatformRow(
                        result: result,
                        maxAbsNet: model.maxAbsPlatformNet
                    )

                    if index < model.platforms.count - 1 {
                        Rectangle()
                            .fill(BBTheme.hairline.opacity(0.4))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }

    // MARK: - Transactions

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Recent transactions")
                    .font(BBTheme.headline(25))
                    .foregroundStyle(BBTheme.ink)

                Spacer(minLength: 8)

                Button {
                    Haptics.tap()
                    model.showingAddSheet = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(BBTheme.gold)
                    .padding(.horizontal, 13)
                    .frame(height: 34)
                    .background {
                        Capsule()
                            .stroke(BBTheme.gold.opacity(0.4), lineWidth: 1)
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(BBPressStyle())
                .accessibilityLabel("Add transaction")
            }

            if model.activityGroups.isEmpty {
                Text("Nothing moved in this window yet. Pull to refresh, or add a transaction.")
                    .font(.system(size: 12))
                    .foregroundStyle(BBTheme.inkMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
            } else {
                ForEach(model.visibleGroups) { group in
                    statsDaySection(group)
                        .padding(.top, 16)
                }

                if model.hiddenTransactionCount > 0 {
                    Button {
                        model.toggleActivityExpansion()
                    } label: {
                        Text("Show \(model.hiddenTransactionCount) earlier transaction\(model.hiddenTransactionCount == 1 ? "" : "s")")
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
                    .padding(.top, 18)
                }
            }
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }

    private func statsDaySection(_ group: StatsActivityGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.1)
                    .foregroundStyle(BBTheme.inkMuted)

                Spacer(minLength: 8)

                Text(homeMoney(cents: group.netCents))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(group.netCents < 0 ? StatsPalette.loss : BBTheme.positive)
                    .monospacedDigit()
            }
            .padding(.bottom, 2)

            ForEach(Array(group.items.enumerated()), id: \.element.id) { index, transaction in
                VStack(spacing: 0) {
                    if index > 0 {
                        Rectangle()
                            .fill(BBTheme.hairline.opacity(0.4))
                            .frame(height: 1)
                    }
                    StatsActivityRow(transaction: transaction)
                }
            }
        }
    }
}

// MARK: - Row

/// One ledger entry: operator mark, direction, optional note, signed amount.
struct StatsActivityRow: View {
    let transaction: StatsTransaction

    private var amountColor: Color {
        transaction.cents < 0 ? StatsPalette.loss : BBTheme.positive
    }

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            HomeCasinoMark(casinoId: transaction.casinoId, size: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BBTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                HStack(spacing: 5) {
                    Text(transaction.direction.flowLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(BBTheme.inkMuted)

                    if let note = transaction.note, !note.isEmpty {
                        Text("· \(note)")
                            .font(.system(size: 11))
                            .foregroundStyle(BBTheme.inkMuted.opacity(0.75))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(homeMoney(cents: transaction.cents))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(amountColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(homeShortDate(transaction.date))
                    .font(.system(size: 10))
                    .foregroundStyle(BBTheme.inkMuted.opacity(0.85))
            }
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [
            transaction.title,
            transaction.direction.flowLabel,
            homeMoney(cents: transaction.cents)
        ]
        if let note = transaction.note, !note.isEmpty {
            parts.append(note)
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    StatsScreen()
}
