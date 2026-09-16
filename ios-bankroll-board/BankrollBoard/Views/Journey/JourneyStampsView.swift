//
//  JourneyStampsView.swift
//  BankrollBoard
//

import SwiftUI

/// Section heading used by both journey sections: index, serif title, trailing accessory.
struct JourneySectionHeading<Accessory: View>: View {
    let index: String
    let title: String
    let caption: String
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(index)
                        .bbEyebrowStyle()
                    Text(title)
                        .font(BBTheme.headline(27))
                        .foregroundStyle(BBTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                accessory()
            }

            Text(caption)
                .font(.system(size: 12))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }
}

/// Horizontally scrolling collection of earned and upcoming stamps.
struct JourneyStampsView: View {
    let stamps: [JourneyStamp]
    let earnedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            JourneySectionHeading(
                index: "01 / Achievements",
                title: "Your stamp collection",
                caption: "A record of completed offers and verified results."
            ) {
                Text("\(earnedCount) earned")
                    .font(.system(size: 11))
                    .foregroundStyle(BBTheme.inkMuted)
                    .padding(.top, 20)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stamps) { stamp in
                        stampCard(stamp)
                    }
                }
                .padding(.vertical, 2)
            }
            .contentMargins(.horizontal, BBTheme.screenMargin, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)

            Text(
                earnedCount > 0
                    ? "Earned from your Journey records."
                    : "Your first stamp marks one completed offer."
            )
            .font(.system(size: 11))
            .foregroundStyle(BBTheme.inkMuted)
            .padding(.horizontal, BBTheme.screenMargin)
        }
    }

    private func stampCard(_ stamp: JourneyStamp) -> some View {
        VStack(spacing: 8) {
            Text(stamp.earned ? "✓ Earned" : "Upcoming")
                .font(.system(size: 9, weight: .semibold))
                .textCase(.uppercase)
                .kerning(1.3)
                .foregroundStyle(stamp.earned ? BBTheme.gold : BBTheme.inkMuted)

            Text(stamp.symbol)
                .font(BBTheme.headline(19))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(stamp.earned ? BBTheme.goldBright : BBTheme.inkMuted)
                .frame(width: 48, height: 48)
                .background {
                    Rectangle()
                        .fill(stamp.earned ? BBTheme.gold.opacity(0.1) : .clear)
                        .overlay {
                            Rectangle().stroke(
                                stamp.earned ? BBTheme.gold.opacity(0.5) : BBTheme.hairline.opacity(0.6),
                                style: .init(lineWidth: 1, dash: stamp.earned ? [] : [3, 3])
                            )
                        }
                }
                .padding(.vertical, 4)

            Text(stamp.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(stamp.earned ? BBTheme.ink : BBTheme.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(stamp.family)
                .font(.system(size: 10))
                .foregroundStyle(BBTheme.inkMuted.opacity(0.85))
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .frame(width: 142, height: 178)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    RadialGradient(
                        colors: [
                            stamp.earned ? BBTheme.gold.opacity(0.07) : .clear,
                            .clear
                        ],
                        center: UnitPoint(x: 0.5, y: 0.4),
                        startRadius: 0,
                        endRadius: 110
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            stamp.earned ? BBTheme.gold.opacity(0.43) : BBTheme.hairline.opacity(0.55),
                            style: .init(lineWidth: 1, dash: stamp.earned ? [] : [4, 4])
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            stamp.earned ? BBTheme.gold.opacity(0.16) : BBTheme.hairline.opacity(0.25),
                            style: .init(lineWidth: 1, dash: stamp.earned ? [] : [3, 3])
                        )
                        .padding(4)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stamp.earned ? "Earned" : "Upcoming"): \(stamp.title), \(stamp.family)")
    }
}
