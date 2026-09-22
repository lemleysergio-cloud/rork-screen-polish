//
//  StatsFlowChart.swift
//  BankrollBoard
//
//  Money flow over time: paired gold/sage columns per slice of the window,
//  with tap-to-inspect instead of the web build's drag scrubbing.
//

import SwiftUI

struct StatsFlowChart: View {
    let buckets: [StatsBucket]
    let selectedIndex: Int?
    let onSelect: (Int?) -> Void

    private let labelGutter: CGFloat = 38

    var body: some View {
        let maxCents = buckets.map { max($0.sentCents, $0.returnedCents) }.max() ?? 0
        let ticks = maxCents > 0 ? homeNiceTicks(min: 0, max: Double(maxCents), count: 4) : [0.0]

        return GeometryReader { proxy in
            let plotWidth = proxy.size.width - labelGutter
            let slot = buckets.isEmpty ? plotWidth : plotWidth / CGFloat(buckets.count)

            ZStack(alignment: .topLeading) {
                canvas(size: proxy.size, ticks: ticks, slot: slot)
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            let position = value.location.x - labelGutter
                            guard position >= 0, !buckets.isEmpty else {
                                onSelect(nil)
                                return
                            }
                            let index = Int((position / slot).rounded(.down))
                            onSelect(buckets.indices.contains(index) ? index : nil)
                        }
                    )

                // Y-axis labels, one per gridline.
                ForEach(Array(ticks.enumerated()), id: \.offset) { _, tick in
                    let fraction = ticks.last ?? 1
                    let y = proxy.size.height - CGFloat(tick / max(fraction, 1)) * proxy.size.height
                    Text(homeAxisLabel(cents: tick, step: ticks.count > 1 ? ticks[1] - ticks[0] : 1))
                        .font(.system(size: 9))
                        .monospacedDigit()
                        .foregroundStyle(BBTheme.inkMuted.opacity(0.85))
                        .frame(width: labelGutter - 6, alignment: .trailing)
                        .position(x: (labelGutter - 6) / 2, y: min(max(y, 5), proxy.size.height - 5))
                }
            }
        }
        .frame(height: 196)
    }

    private func canvas(size: CGSize, ticks: [Double], slot: CGFloat) -> some View {
        Canvas { context, size in
            let plotWidth = size.width - labelGutter
            let top = ticks.last ?? 1
            let plotHeight = size.height

            // Gridlines and baseline.
            for tick in ticks {
                let y = plotHeight - CGFloat(tick / max(top, 1)) * plotHeight
                let line = CGRect(x: labelGutter, y: y, width: plotWidth, height: 1)
                context.fill(Path(line), with: .color(BBTheme.hairline.opacity(0.35)))
            }

            guard !buckets.isEmpty else { return }
            let barWidth = slot * 0.26
            let pairGap: CGFloat = 2.5

            for (index, bucket) in buckets.enumerated() {
                let centre = labelGutter + CGFloat(Double(index) + 0.5) * slot
                let isDimmed = selectedIndex != nil && selectedIndex != index
                let opacity: Double = isDimmed ? 0.35 : 1

                func bar(_ value: Int, offset: CGFloat, color: Color) {
                    guard value > 0 else { return }
                    let height = max(2, CGFloat(Double(value) / max(Double(top), 1)) * plotHeight)
                    let rect = CGRect(
                        x: centre + offset - barWidth / 2,
                        y: plotHeight - height,
                        width: barWidth,
                        height: height
                    )
                    let path = Path(roundedRect: rect, cornerRadius: 2.5)
                    context.fill(path, with: .color(color.opacity(opacity)))
                }

                bar(bucket.sentCents, offset: -barWidth / 2 - pairGap / 2, color: StatsPalette.sent)
                bar(bucket.returnedCents, offset: barWidth / 2 + pairGap / 2, color: StatsPalette.sage)

                // Highlight under the selected column.
                if selectedIndex == index {
                    let highlight = CGRect(
                        x: centre - slot / 2 + 2,
                        y: 0,
                        width: slot - 4,
                        height: size.height
                    )
                    context.fill(Path(highlight), with: .color(BBTheme.gold.opacity(0.07)))
                }

                // X label under each column (spaced out when they get tight).
                let everyNth = buckets.count > 9 ? 2 : 1
                if index % everyNth == 0 || index == buckets.count - 1 {
                    context.draw(
                        Text(bucket.label)
                            .font(.system(size: 9))
                            .foregroundColor(BBTheme.inkMuted.opacity(0.85)),
                        at: CGPoint(x: centre, y: size.height + 10)
                    )
                }
            }
        }
        .padding(.bottom, 14)
    }
}

/// Readout under the chart: either the tapped period's amounts or a hint.
struct StatsBucketReadout: View {
    let bucket: StatsBucket?
    let windowLabel: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let bucket {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(bucket.label.uppercased()) · \(windowLabel.uppercased())")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(0.8)
                        .foregroundStyle(BBTheme.inkMuted)

                    HStack(spacing: 12) {
                        Label(homeMoney(cents: bucket.sentCents, showsPlus: false), systemImage: "arrow.up.right")
                            .foregroundStyle(StatsPalette.sent)
                        Label(homeMoney(cents: bucket.returnedCents, showsPlus: false), systemImage: "arrow.down.left")
                            .foregroundStyle(StatsPalette.sage)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                }

                Spacer(minLength: 8)

                Text(homeMoney(cents: bucket.netCents))
                    .font(BBTheme.money(20))
                    .foregroundStyle(bucket.netCents < 0 ? StatsPalette.loss : BBTheme.positive)
                    .monospacedDigit()
            } else {
                Text("Tap any bar to see what moved in that period.")
                    .font(.system(size: 12))
                    .foregroundStyle(BBTheme.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(minHeight: 62)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BBTheme.surface.opacity(0.65))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            bucket != nil ? BBTheme.gold.opacity(0.28) : BBTheme.hairline.opacity(0.6),
                            lineWidth: 1
                        )
                    }
        }
        .animation(.easeOut(duration: 0.2), value: bucket)
    }
}
