//
//  JourneyTrailView.swift
//  BankrollBoard
//

import SwiftUI

/// The lower offer trail: filter tabs plus a dashed route threading numbered offer cards.
struct JourneyTrailView: View {
    let offers: [JourneyOffer]
    let filter: JourneyFilter
    let caption: String
    let onSelectFilter: (JourneyFilter) -> Void
    let onOpenOffer: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            JourneySectionHeading(
                index: "02 / The offer map",
                title: "Your offer trail",
                caption: caption
            ) {
                JourneyCompass()
                    .padding(.top, 14)
            }

            JourneyFilterBar(selected: filter, onSelect: onSelectFilter)
                .padding(.top, 20)
                .padding(.bottom, 24)

            if offers.isEmpty {
                emptyState
            } else {
                trail
            }
        }
    }

    private var trail: some View {
        VStack(spacing: 0) {
            ForEach(Array(offers.enumerated()), id: \.element.id) { index, offer in
                JourneyOfferCard(
                    offer: offer,
                    index: index,
                    isLast: index == offers.count - 1,
                    action: { onOpenOffer(offer.id) }
                )
            }
        }
        .padding(.horizontal, BBTheme.screenMargin)
        .background(alignment: .topLeading) {
            // Dotted paper grid, matching the web offer map.
            GridDots()
                .allowsHitTesting(false)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(filter == .active ? "No active offers" : "No verified recommendations available")
                .font(BBTheme.headline(20))
                .foregroundStyle(BBTheme.ink)
            Text("Choose All Offers to review the state's casinos and verification status.")
                .font(.system(size: 13))
                .foregroundStyle(BBTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .stroke(BBTheme.hairline.opacity(0.6), style: .init(lineWidth: 1, dash: [5, 4]))
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }
}

// MARK: - Filter bar

/// Segmented filter with a solid gold active pill.
struct JourneyFilterBar: View {
    let selected: JourneyFilter
    let onSelect: (JourneyFilter) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(JourneyFilter.allCases) { option in
                let isActive = option == selected
                Button(action: {
                    Haptics.selection()
                    onSelect(option)
                }) {
                    Text(option.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isActive ? BBTheme.canvasDeep : BBTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isActive ? BBTheme.gold : .clear)
                        }
                }
                .buttonStyle(BBPressStyle())
                .accessibilityAddTraits(isActive ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(BBTheme.canvasDeep.opacity(0.45))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(BBTheme.hairline.opacity(0.55), lineWidth: 1)
                }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: selected)
        .padding(.horizontal, BBTheme.screenMargin)
    }
}

// MARK: - Offer card

/// One offer on the trail: numbered route node, brand mark, and the money breakdown.
struct JourneyOfferCard: View {
    let offer: JourneyOffer
    let index: Int
    let isLast: Bool
    let action: () -> Void

    private var isCurrent: Bool { offer.state == .current }
    private var isComplete: Bool { offer.state == .completed }

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            routeNode

            Button(action: {
                Haptics.tap()
                action()
            }) {
                card
            }
            .buttonStyle(BBPressStyle())
            .accessibilityLabel("\(offer.rankLabel): \(offer.name). \(offer.state.trailLabel).")
            .accessibilityHint("Opens offer details")
        }
        .padding(.bottom, isLast ? 4 : 25)
    }

    private var routeNode: some View {
        VStack(spacing: 0) {
            Text(isComplete ? "✓" : offer.trailMarker)
                .font(.system(size: isComplete ? 16 : 11, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(nodeInk)
                .frame(width: 32, height: 32)
                .background {
                    Circle()
                        .fill(nodeFill)
                        .overlay { Circle().stroke(nodeStroke, lineWidth: 1) }
                }
                .overlay {
                    if isCurrent {
                        Circle()
                            .stroke(BBTheme.gold.opacity(0.28), lineWidth: 5)
                            .blur(radius: 2)
                    }
                }
                .padding(.top, 21)

            if !isLast {
                TrailWeave(bulgesLeft: index.isMultiple(of: 2))
                    .stroke(
                        BBTheme.gold.opacity(0.5),
                        style: .init(lineWidth: 1.5, lineCap: .round, dash: [3, 5])
                    )
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 3)
            }
        }
        .frame(width: 32)
    }

    private var nodeInk: Color {
        if isCurrent { BBTheme.canvasDeep }
        else if isComplete { BBTheme.positive }
        else { BBTheme.gold.opacity(0.85) }
    }

    private var nodeFill: Color {
        if isCurrent { BBTheme.gold }
        else if isComplete { BBTheme.surfaceRaised }
        else { BBTheme.canvas }
    }

    private var nodeStroke: Color {
        if isCurrent { BBTheme.gold }
        else if isComplete { BBTheme.positive.opacity(0.6) }
        else { BBTheme.gold.opacity(0.45) }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                JourneyBrandTile(mark: offer.mark, side: 42)
                    .padding(.top, 22)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(offer.rankLabel.uppercased()) · \(offer.state.trailLabel.uppercased())")
                            .font(.system(size: 9, weight: .semibold))
                            .kerning(0.5)
                            .foregroundStyle(isComplete ? BBTheme.positive : BBTheme.gold)

                        Spacer(minLength: 0)

                        Text(offer.verificationLabel.uppercased())
                            .font(.system(size: 8, weight: .regular))
                            .kerning(0.5)
                            .foregroundStyle(BBTheme.inkMuted)
                    }

                    Text(offer.name)
                        .font(BBTheme.headline(21))
                        .foregroundStyle(BBTheme.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(offer.headline)
                        .font(.system(size: 11))
                        .foregroundStyle(BBTheme.inkMuted)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BBTheme.gold.opacity(0.8))
                    .padding(.top, 26)
            }

            VStack(spacing: 0) {
                summaryRow(label: "You put in", value: offer.youPutIn)
                summaryRow(label: "You may receive", value: offer.youMayReceive)
                summaryRow(label: "Main catch", value: offer.mainCatch, muted: true)
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: isCurrent
                            ? [Color(rgb: 0x2C3D2B), Color(rgb: 0x203426)]
                            : [Color(rgb: 0x23382B), Color(rgb: 0x1D3024)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardStroke, lineWidth: isCurrent ? 1.5 : 1)
                }
                .shadow(color: BBTheme.canvasDeep.opacity(0.45), radius: 9, y: 5)
        }
    }

    private var cardStroke: Color {
        if isCurrent { BBTheme.gold.opacity(0.65) }
        else if isComplete { BBTheme.positive.opacity(0.3) }
        else { BBTheme.hairline.opacity(0.55) }
    }

    private func summaryRow(label: String, value: String, muted: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 9))
                .kerning(0.4)
                .foregroundStyle(BBTheme.inkMuted)
                .frame(width: 79, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(.system(size: 11, weight: muted ? .regular : .medium))
                .foregroundStyle(muted ? BBTheme.inkMuted : Color(rgb: 0xE5DDBC))
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 8)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BBTheme.hairline.opacity(0.35))
                .frame(height: 1)
        }
    }
}

// MARK: - Small parts

/// Rounded operator tile with monogram, used on cards and in the sheet.
struct JourneyBrandTile: View {
    let mark: JourneyBrandMark
    let side: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: side * 0.24)
            .fill(
                LinearGradient(
                    colors: [Color(rgb: mark.top), Color(rgb: mark.bottom)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                Text(mark.monogram)
                    .font(.system(size: side * 0.32, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(Color(rgb: mark.ink))
                    .padding(side * 0.14)
            }
            .overlay {
                RoundedRectangle(cornerRadius: side * 0.24)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
            .frame(width: side, height: side)
    }
}

/// Thin-line compass used as the trail section accessory.
struct JourneyCompass: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(BBTheme.gold, lineWidth: 0.75)
            Path { path in
                path.move(to: CGPoint(x: 21.5, y: 3))
                path.addLine(to: CGPoint(x: 26.5, y: 21.5))
                path.addLine(to: CGPoint(x: 21.5, y: 40))
                path.addLine(to: CGPoint(x: 16.5, y: 21.5))
                path.closeSubpath()
                path.move(to: CGPoint(x: 3, y: 21.5))
                path.addLine(to: CGPoint(x: 40, y: 21.5))
            }
            .stroke(BBTheme.gold, lineWidth: 0.75)
        }
        .frame(width: 43, height: 43)
        .opacity(0.65)
        .rotationEffect(.degrees(25))
        .accessibilityHidden(true)
    }
}

/// Hand-drawn treasure-map connector: a dashed path that bows out to one side
/// between two route markers, alternating direction down the trail.
private struct TrailWeave: Shape {
    let bulgesLeft: Bool

    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        let reach = min(rect.width * 0.46, 13) * (bulgesLeft ? -1 : 1)
        let third = rect.height / 3

        var path = Path()
        path.move(to: CGPoint(x: midX, y: rect.minY))
        // Bow away from the column, then curl back to meet the next marker.
        path.addCurve(
            to: CGPoint(x: midX + reach, y: rect.minY + third * 1.5),
            control1: CGPoint(x: midX + reach * 0.35, y: rect.minY + third * 0.4),
            control2: CGPoint(x: midX + reach * 1.15, y: rect.minY + third * 0.95)
        )
        path.addCurve(
            to: CGPoint(x: midX, y: rect.maxY),
            control1: CGPoint(x: midX + reach * 0.85, y: rect.minY + third * 2.15),
            control2: CGPoint(x: midX + reach * 0.2, y: rect.maxY - third * 0.35)
        )
        return path
    }
}

/// Faint dot grid behind the trail cards.
private struct GridDots: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 20
            let dot: CGFloat = 1.4
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: dot, height: dot)),
                        with: .color(Color(rgb: 0xB9C4A5).opacity(0.09))
                    )
                    x += spacing
                }
                y += spacing
            }
        }
    }
}
