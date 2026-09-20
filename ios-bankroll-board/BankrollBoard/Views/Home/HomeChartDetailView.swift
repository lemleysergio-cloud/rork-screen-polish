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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [JourneyPalette.canvasDeep, JourneyPalette.canvas],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                closeButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 4)

                Text("BANKROLL OVER TIME")
                    .bbEyebrowStyle()
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 8)

                balance
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 10)

                delta
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 10)

                Rectangle()
                    .fill(BBTheme.hairline.opacity(0.55))
                    .frame(height: 1)
                    .padding(.horizontal, BBTheme.screenMargin)
                    .padding(.top, 20)

                HomeBankrollChart(
                    points: model.series,
                    timeframe: model.timeframe,
                    scrubIndex: model.scrubIndex,
                    onScrub: { model.scrub(to: $0) },
                    height: 360
                )
                .padding(.horizontal, BBTheme.screenMargin)
                .padding(.top, 22)

                Spacer(minLength: 12)

                HomeTimeframeBar(
                    selection: model.timeframe,
                    onSelect: { model.select(timeframe: $0) }
                )
                .padding(.horizontal, BBTheme.screenMargin)
                .padding(.bottom, 12)
            }
        }
        .preferredColorScheme(.dark)
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
                .foregroundStyle(BBTheme.ink)
                .frame(width: 44, height: 44)
                .background {
                    Circle().stroke(BBTheme.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(BBPressStyle())
        .accessibilityLabel("Close chart")
    }

    private var balance: some View {
        let parts = homeBalanceParts(cents: model.settledCents)
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(parts.dollars)
                .font(BBTheme.money(42))
                .foregroundStyle(BBTheme.positive)
            Text(parts.cents)
                .font(BBTheme.money(28))
                .foregroundStyle(BBTheme.positive.opacity(0.85))
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
                .foregroundStyle(BBTheme.inkMuted)
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(isNegative ? Color(rgb: 0xE2928A) : BBTheme.positive)
    }
}
