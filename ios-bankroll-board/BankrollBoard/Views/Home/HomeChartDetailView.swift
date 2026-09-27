//
//  HomeChartDetailView.swift
//  BankrollBoard
//
//  Full-screen bankroll chart with more vertical room for inspection.
//

import SwiftUI

struct HomeChartDetailView: View {
    let model: HomeViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.homePalette) private var palette

    var body: some View {
        ZStack {
            HomeBackdrop()

            VStack(alignment: .leading, spacing: 0) {
                closeButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 4)

                Text("BANKROLL OVER TIME")
                    .homeEyebrowStyle(palette)
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 8)

                balance
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 10)

                delta
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 10)

                Rectangle()
                    .fill(palette.hairline.opacity(0.55))
                    .frame(height: 1)
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 20)

                // Fills the space between the header and the timeframe bar,
                // which is the whole point of going full screen.
                HomeBankrollChart(
                    points: model.series,
                    timeframe: model.timeframe,
                    scrubProgress: model.scrubProgress,
                    onScrub: { model.scrub(to: $0) },
                    expands: true
                )
                .padding(.horizontal, BBTheme.screenMargin)
                .padding(.top, 22)
                .padding(.bottom, 24)

                HomeTimeframeBar(
                    selection: model.timeframe,
                    onSelect: { model.select(timeframe: $0) }
                )
                .padding(.horizontal, BBTheme.screenMargin)
                .padding(.bottom, 12)
            }
        }
        .preferredColorScheme(palette.colorScheme)
        .accessibilityIdentifier("home.chartDetail")
    }

    private var closeButton: some View {
        Button {
            Haptics.tap()
            model.scrub(to: nil)
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(palette.ink)
                .frame(width: 44, height: 44)
                .background {
                    Circle().stroke(palette.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(BBPressStyle())
        .accessibilityLabel("Close chart")
    }

    private var balance: some View {
        let parts = homeBalanceParts(cents: model.displayedBalanceCents)
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(parts.dollars)
                .font(BBTheme.money(42))
                .foregroundStyle(palette.positive)
            Text(parts.cents)
                .font(BBTheme.money(28))
                .foregroundStyle(palette.positive.opacity(0.85))
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    private var delta: some View {
        let value = model.periodDeltaCents
        let isNegative = value < 0
        return HStack(spacing: 7) {
            Image(systemName: isNegative ? "arrowtriangle.down.fill" : "arrowtriangle.up.fill")
                .font(.system(size: 9))
            Text(homeMoney(cents: value))
                .monospacedDigit()
            if let percent = model.periodPercent {
                Text("(\(percent))")
                    .monospacedDigit()
            }
            Text(model.timeframe.long)
                .foregroundStyle(palette.inkMuted)
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(isNegative ? palette.negative : palette.positive)
    }
}
