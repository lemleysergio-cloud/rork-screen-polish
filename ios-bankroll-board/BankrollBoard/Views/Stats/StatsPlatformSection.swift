//
//  StatsPlatformSection.swift
//  BankrollBoard
//
//  Per-operator results: logo, money in and out, what you netted, and a
//  diverging bar that shows the direction of the result at a glance.
//

import SwiftUI

struct StatsPlatformRow: View {
    let result: StatsPlatformResult
    let maxAbsNet: Int

    private var netColor: Color {
        result.netCents < 0 ? StatsPalette.loss : BBTheme.positive
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 13) {
                HomeCasinoMark(casinoId: result.casinoId, size: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(HomeCasino.name(for: result.casinoId))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(BBTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text("Sent \(homeMoney(cents: result.sentCents, showsPlus: false)) · Came back \(homeMoney(cents: result.returnedCents, showsPlus: false))")
                        .font(.system(size: 11))
                        .foregroundStyle(BBTheme.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(homeMoney(cents: result.netCents))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(netColor)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("NET")
                        .font(.system(size: 8, weight: .bold))
                        .kerning(0.9)
                        .foregroundStyle(BBTheme.inkMuted.opacity(0.8))
                }
            }
            .padding(.vertical, 14)

            resultBar
                .padding(.bottom, 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// Centre-anchored capsule: grows right when the operator paid you back
    /// more than you sent, left when it kept more of your money.
    private var resultBar: some View {
        GeometryReader { proxy in
            let half = proxy.size.width / 2
            let extent = maxAbsNet > 0
                ? CGFloat(Double(abs(result.netCents)) / Double(maxAbsNet)) * (half - 2)
                : 0
            let isPositive = result.netCents >= 0

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(BBTheme.hairline.opacity(0.5))
                    .frame(width: 1)
                    .position(x: half, y: proxy.size.height / 2)

                Capsule()
                    .fill(isPositive ? BBTheme.positive : StatsPalette.loss)
                    .frame(width: max(extent, result.netCents == 0 ? 0 : 3))
                    .offset(x: isPositive ? half : half - extent)
            }
        }
        .frame(height: 5)
        .padding(.leading, 55)
    }

    private var accessibilityText: String {
        let direction = result.netCents >= 0 ? "gave back more than you sent" : "kept more than it gave back"
        return "\(HomeCasino.name(for: result.casinoId)). Sent \(homeMoney(cents: result.sentCents, showsPlus: false)), came back \(homeMoney(cents: result.returnedCents, showsPlus: false)). Net \(homeMoney(cents: result.netCents)) — \(direction)."
    }
}
