//
//  JourneyOrbitView.swift
//  BankrollBoard
//

import SwiftUI

/// The spatial offer selector: a gold orbit that sweeps with the user's swipe,
/// operator nodes riding the ring, and a 3D die tumbling at the center.
struct JourneyOrbitView: View {
    let offers: [JourneyOffer]
    let phase: Double
    let focusIndex: Int
    let rollToken: Int
    let rankCaption: String
    let onDragChange: (Double) -> Void
    let onDragEnd: () -> Void
    let onNodeTap: (String) -> Void
    let onRoll: () -> Void
    let onDieLand: (Int) -> Void

    /// Angular gap between neighbouring nodes, in degrees.
    private let spread: Double = 38
    /// Horizontal drag distance that advances exactly one node.
    private let stepWidth: Double = 96
    private let ringTilt: Double = -5

    @State private var isDragging: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let center = CGPoint(x: size.width / 2, y: size.height * 0.56)
            let radii = CGSize(width: size.width * 0.44, height: size.height * 0.28)

            ZStack {
                aura(center: center, radii: radii)

                ring(center: center, radii: radii, isFront: false)

                die(size: size)

                ring(center: center, radii: radii, isFront: true)

                ForEach(visibleNodes, id: \.offer.id) { entry in
                    node(for: entry, center: center, radii: radii)
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .gesture(swipe)
        }
        .frame(height: 356)
        .overlay(alignment: .bottom) { swipeHint }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Offer orbit")
        .accessibilityHint("Swipe left or right to explore offers and tumble the die")
        .accessibilityAdjustableAction { direction in
            onRoll()
            switch direction {
            case .increment: onDragChange(1); onDragEnd()
            case .decrement: onDragChange(-1); onDragEnd()
            @unknown default: break
            }
        }
    }

    // MARK: - Pieces

    private func aura(center: CGPoint, radii: CGSize) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [BBTheme.gold.opacity(0.13), BBTheme.gold.opacity(0.03), .clear],
                    center: .center,
                    startRadius: 4,
                    endRadius: radii.width
                )
            )
            .frame(width: radii.width * 2.1, height: radii.height * 2.4)
            .position(center)
            .blur(radius: 18)
            .allowsHitTesting(false)
    }

    /// Half of the orbit. The bright tracer arc is anchored to `phase`, so the
    /// gold light travels around the ring exactly as the user swipes.
    private func ring(center: CGPoint, radii: CGSize, isFront: Bool) -> some View {
        let rect = CGRect(
            x: center.x - radii.width,
            y: center.y - radii.height,
            width: radii.width * 2,
            height: radii.height * 2
        )
        let sweepStart = sweepAnchor
        return ZStack {
            OrbitArc(rect: rect, isFront: isFront)
                .stroke(BBTheme.canvasDeep.opacity(0.65), style: .init(lineWidth: 5, lineCap: .round))
                .blur(radius: 5)
                .offset(y: 3)

            OrbitArc(rect: rect, isFront: isFront)
                .stroke(
                    BBTheme.goldSweep,
                    style: .init(lineWidth: isFront ? 2.4 : 1.5, lineCap: .round)
                )
                .opacity(isFront ? 0.95 : 0.5)

            // Traveling highlight: sits under the focused node and follows the swipe.
            OrbitArc(rect: rect, isFront: isFront)
                .trim(from: sweepStart, to: sweepStart + 0.16)
                .stroke(
                    LinearGradient(
                        colors: [.clear, BBTheme.goldBright, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: .init(lineWidth: isFront ? 4.2 : 2.6, lineCap: .round)
                )
                .opacity(isFront ? 1 : 0.4)
                .blur(radius: isFront ? 1.5 : 2.5)
                .shadow(color: BBTheme.gold.opacity(0.7), radius: 9)
        }
        .rotationEffect(.degrees(ringTilt), anchor: .center)
        .allowsHitTesting(false)
    }

    /// Normalized start of the traveling highlight, derived from swipe phase.
    private var sweepAnchor: CGFloat {
        let fraction = (phase - Double(focusIndex)) * 0.12
        let wrapped = (0.42 + fraction).truncatingRemainder(dividingBy: 1)
        return CGFloat(wrapped < 0 ? wrapped + 1 : wrapped)
    }

    /// The hero die. Sits at 42% of the container height (matching the web layout)
    /// and is purely presentational: the ring gesture drives its tumble.
    private func die(size: CGSize) -> some View {
        let side = min(size.width * 0.62, 236)
        return ZStack {
            Ellipse()
                .fill(BBTheme.canvasDeep.opacity(0.6))
                .frame(width: side * 0.7, height: side * 0.15)
                .blur(radius: 14)
                .offset(y: side * 0.46)

            Ellipse()
                .fill(BBTheme.gold.opacity(0.1))
                .frame(width: side * 0.9, height: side * 0.22)
                .blur(radius: 22)
                .offset(y: side * 0.4)

            JourneyDieView(rollToken: rollToken, onLand: onDieLand)
                .frame(width: side, height: side)
                .scaleEffect(isDragging ? 1.04 : 1)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isDragging)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .position(x: size.width / 2, y: size.height * 0.42)
    }

    private func node(for entry: OrbitNode, center: CGPoint, radii: CGSize) -> some View {
        let angle = Angle.degrees(90 + (Double(entry.index) - phase) * spread)
        let depth = sin(angle.radians)
        let point = CGPoint(
            x: center.x + radii.width * cos(angle.radians),
            y: center.y + radii.height * depth
        )
        let normalizedDepth = (depth + 1) / 2
        let scale = 0.66 + 0.34 * normalizedDepth
        let isFocused = entry.isFocused

        return JourneyOrbitNode(
            offer: entry.offer,
            isFocused: isFocused,
            action: { onNodeTap(entry.offer.id) }
        )
        .scaleEffect(scale)
        .opacity(0.35 + 0.65 * normalizedDepth)
        .blur(radius: isFocused ? 0 : (1 - normalizedDepth) * 2.2)
        .position(point)
        .zIndex(depth + (isFocused ? 4 : 0))
    }

    private var swipeHint: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left")
                Text("Swipe to explore and roll")
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(BBTheme.inkMuted)

            Text(rankCaption)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(BBTheme.inkMuted.opacity(0.75))
        }
        .opacity(isDragging ? 0.3 : 1)
        .animation(.easeOut(duration: 0.2), value: isDragging)
        .allowsHitTesting(false)
    }

    // MARK: - Gesture

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                // The first movement of a swipe sets the die tumbling.
                if !isDragging {
                    isDragging = true
                    onRoll()
                }
                onDragChange(-Double(value.translation.width) / stepWidth)
            }
            .onEnded { _ in
                isDragging = false
                onDragEnd()
            }
    }

    // MARK: - Node windowing

    private struct OrbitNode {
        let index: Int
        let offer: JourneyOffer
        let isFocused: Bool
    }

    /// Only the five nodes nearest the focus are rendered.
    private var visibleNodes: [OrbitNode] {
        offers.enumerated()
            .filter { abs(Double($0.offset) - phase) <= 2.4 }
            .map { OrbitNode(index: $0.offset, offer: $0.element, isFocused: $0.offset == focusIndex) }
    }
}

// MARK: - Node

/// A single operator riding the orbit: rank, brand tile, name, and journey state.
private struct JourneyOrbitNode: View {
    let offer: JourneyOffer
    let isFocused: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            VStack(spacing: 6) {
                if isFocused {
                    Text("Selected")
                        .font(.system(size: 9, weight: .bold))
                        .textCase(.uppercase)
                        .kerning(1)
                        .foregroundStyle(BBTheme.canvasDeep)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background { Capsule().fill(BBTheme.gold) }
                        .transition(.scale.combined(with: .opacity))
                }

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(rgb: offer.mark.top), Color(rgb: offer.mark.bottom)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            Circle().stroke(
                                isFocused ? BBTheme.gold : BBTheme.hairline.opacity(0.7),
                                lineWidth: isFocused ? 2.4 : 1
                            )
                        }
                        .overlay {
                            Text(offer.mark.monogram)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .foregroundStyle(Color(rgb: offer.mark.ink))
                                .padding(6)
                        }
                        .shadow(color: BBTheme.canvasDeep.opacity(0.6), radius: 8, y: 4)

                    if isFocused {
                        Circle()
                            .stroke(BBTheme.gold.opacity(0.35), lineWidth: 8)
                            .blur(radius: 5)
                    }
                }
                .frame(width: 62, height: 62)
                .overlay(alignment: .topLeading) { rankBadge }
                .overlay(alignment: .bottomTrailing) { stateDot }

                VStack(spacing: 1) {
                    Text(offer.shortName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isFocused ? BBTheme.ink : BBTheme.inkMuted)
                        .lineLimit(1)

                    Text(offer.state.nodeLabel)
                        .font(.system(size: 9, weight: .bold))
                        .textCase(.uppercase)
                        .kerning(0.9)
                        .foregroundStyle(isFocused ? BBTheme.gold : BBTheme.inkMuted.opacity(0.7))
                }
                .frame(width: 104)
            }
        }
        .buttonStyle(BBPressStyle())
        .animation(.spring(response: 0.34, dampingFraction: 0.78), value: isFocused)
        .accessibilityLabel("\(offer.rankLabel): \(offer.name), \(offer.state.trailLabel)")
        .accessibilityAddTraits(isFocused ? [.isSelected] : [])
    }

    private var rankBadge: some View {
        Text(offer.rank.map(String.init) ?? "•")
            .font(.system(size: 11, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(isFocused ? BBTheme.canvasDeep : BBTheme.gold)
            .frame(width: 22, height: 22)
            .background {
                Circle()
                    .fill(isFocused ? BBTheme.gold : BBTheme.canvas)
                    .overlay { Circle().stroke(BBTheme.gold.opacity(0.7), lineWidth: 1) }
            }
            .offset(x: -4, y: -2)
    }

    @ViewBuilder
    private var stateDot: some View {
        switch offer.state {
        case .completed:
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(BBTheme.canvasDeep)
                .frame(width: 20, height: 20)
                .background { Circle().fill(BBTheme.positive) }
                .offset(x: 2, y: 2)
        case .current:
            Circle()
                .fill(BBTheme.positive)
                .frame(width: 16, height: 16)
                .overlay { Circle().stroke(BBTheme.canvas, lineWidth: 2) }
                .offset(x: 2, y: 2)
        case .next, .ready, .future:
            EmptyView()
        }
    }
}

// MARK: - Arc shape

/// Front (lower) or back (upper) half of the orbit ellipse.
private struct OrbitArc: Shape {
    let rect: CGRect
    let isFront: Bool

    func path(in _: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let rx = rect.width / 2
        let ry = rect.height / 2
        let start: Double = isFront ? 0 : 180
        var path = Path()
        for step in 0...90 {
            let degrees = start + Double(step) * 2
            let radians = degrees * .pi / 180
            let point = CGPoint(
                x: center.x + rx * cos(radians),
                y: center.y + ry * sin(radians)
            )
            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}
