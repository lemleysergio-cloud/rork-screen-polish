//
//  JourneyHeaderView.swift
//  BankrollBoard
//

import SwiftUI

/// Journey hero header: completion ring, title block, and state picker button.
struct JourneyHeaderView: View {
    let completed: Int
    let total: Int
    let regionName: String
    let onChooseRegion: () -> Void

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ring

            VStack(alignment: .leading, spacing: 4) {
                Text("Offer map")
                    .bbEyebrowStyle()

                Text("Journey")
                    .font(BBTheme.headline(38))
                    .foregroundStyle(BBTheme.ink)

                Text("Compare the money before you start")
                    .font(.system(size: 14))
                    .foregroundStyle(BBTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                Haptics.tap()
                onChooseRegion()
            }) {
                HStack(spacing: 6) {
                    Text(regionName)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(BBTheme.ink)
                .padding(.horizontal, 13)
                .frame(height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(BBTheme.canvasDeep.opacity(0.75))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(BBTheme.gold.opacity(0.45), lineWidth: 1)
                        }
                }
            }
            .buttonStyle(BBPressStyle())
            .frame(maxWidth: 132)
            .accessibilityLabel("Choose bonus state, currently \(regionName)")
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(BBTheme.hairline.opacity(0.55), lineWidth: 2)

            Circle()
                .trim(from: 0, to: max(0.001, fraction))
                .stroke(BBTheme.gold, style: .init(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(
                    RadialGradient(
                        colors: [BBTheme.gold.opacity(0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 34
                    )
                )

            VStack(spacing: -2) {
                Text("\(completed)")
                    .font(BBTheme.money(24))
                    .foregroundStyle(BBTheme.gold)
                Text("/\(total)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(BBTheme.inkMuted)
            }
        }
        .frame(width: 68, height: 68)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: fraction)
        .accessibilityLabel("\(completed) of \(total) offers complete in \(regionName)")
    }
}

/// Three-column money summary framed by hairlines.
struct JourneyMoneyBoard: View {
    let money: JourneyMoney
    let regionName: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            column(
                label: "Verified net profit",
                value: money.verifiedNetProfit < 0
                    ? "-$\(abs(money.verifiedNetProfit))"
                    : "$\(money.verifiedNetProfit)",
                caption: "Matched deposit and payout",
                highlight: money.verifiedNetProfit >= 0
            )

            divider

            column(
                label: "Remaining opportunity",
                value: "$\(money.remainingOpportunity)",
                caption: "Estimate, not guaranteed",
                highlight: false
            )

            divider

            column(
                label: "\(regionName) offers complete",
                value: "\(money.completedInRegion)/\(money.totalInRegion)",
                caption: "\(money.completedAllRegions) completed across all states",
                highlight: false
            )
        }
        .padding(.vertical, 18)
        .overlay(alignment: .top) { hairline }
        .overlay(alignment: .bottom) { hairline }
        .padding(.horizontal, BBTheme.screenMargin)
    }

    private var hairline: some View {
        Rectangle()
            .fill(BBTheme.hairline.opacity(0.6))
            .frame(height: 1)
    }

    private var divider: some View {
        Rectangle()
            .fill(BBTheme.hairline.opacity(0.45))
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }

    private func column(label: String, value: String, caption: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .textCase(.uppercase)
                .kerning(0.7)
                .foregroundStyle(BBTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 28, alignment: .top)

            Text(value)
                .font(BBTheme.money(25))
                .monospacedDigit()
                .foregroundStyle(highlight ? BBTheme.positive : BBTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(caption)
                .font(.system(size: 10))
                .foregroundStyle(BBTheme.inkMuted.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
    }
}
