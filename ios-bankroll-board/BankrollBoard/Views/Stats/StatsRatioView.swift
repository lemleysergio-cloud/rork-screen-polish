//
//  StatsRatioView.swift
//  BankrollBoard
//
//  The split: a simple ring showing what share of all moved money went out
//  versus came back, with the two amounts beside it.
//

import SwiftUI

struct StatsRatioView: View {
    let sentCents: Int
    let returnedCents: Int

    private var totalCents: Int { sentCents + returnedCents }

    private var sentShare: Double {
        guard totalCents > 0 else { return 0.5 }
        return Double(sentCents) / Double(totalCents)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            ring
                .frame(width: 132, height: 132)

            VStack(alignment: .leading, spacing: 14) {
                legendRow(
                    color: StatsPalette.sent,
                    title: "Went to apps",
                    cents: sentCents,
                    symbol: "arrow.up.right"
                )
                legendRow(
                    color: StatsPalette.sage,
                    title: "Came back",
                    cents: returnedCents,
                    symbol: "arrow.down.left"
                )

                if totalCents > 0 {
                    Text("Of all the money you moved.")
                        .font(.system(size: 11))
                        .foregroundStyle(BBTheme.inkMuted.opacity(0.85))
                }
            }

            Spacer(minLength: 0)
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

    private var ring: some View {
        let parts = homeBalanceParts(cents: totalCents)
        return ZStack {
            Circle()
                .stroke(BBTheme.hairline.opacity(0.35), lineWidth: 15)

            if totalCents > 0 {
                Circle()
                    .trim(from: 0, to: sentShare)
                    .stroke(StatsPalette.sent, style: StrokeStyle(lineWidth: 15, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: min(sentShare, 0.9999), to: 1)
                    .stroke(StatsPalette.sage, style: StrokeStyle(lineWidth: 15, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text("TOTAL MOVED")
                    .font(.system(size: 8, weight: .bold))
                    .kerning(1)
                    .foregroundStyle(BBTheme.inkMuted)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(parts.dollars)
                        .font(BBTheme.money(21))
                    Text(parts.cents)
                        .font(BBTheme.money(14))
                }
                .foregroundStyle(BBTheme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 22)
        }
        .animation(.easeInOut(duration: 0.45), value: sentShare)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func legendRow(color: Color, title: String, cents: Int, symbol: String) -> some View {
        let share = totalCents > 0 ? Double(cents) / Double(totalCents) * 100 : 0
        return HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(BBTheme.inkMuted)

                Text(homeMoney(cents: cents, showsPlus: false))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(BBTheme.ink)
                    .monospacedDigit()
            }

            Spacer(minLength: 4)

            Text(String(format: "%.0f%%", share))
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(homeMoney(cents: cents, showsPlus: false)), \(Int(share.rounded())) percent")
    }

    private var accessibilityText: String {
        guard totalCents > 0 else { return "No money moved yet" }
        let sentPercent = Int((sentShare * 100).rounded())
        return "Total moved \(homeMoney(cents: totalCents, showsPlus: false)). \(sentPercent) percent went to apps, \(100 - sentPercent) percent came back."
    }
}
