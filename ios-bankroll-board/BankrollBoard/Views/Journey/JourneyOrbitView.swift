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

    /// Horizontal drag distance that advances exactly one node.
    private let stepWidth: Double = 96
    /// The ring is tilted in space, Saturn-style; nodes ride the same rotated plane.
    private let ringTilt: Double = -10

    @State private var isDragging: Bool = false

    /// Nodes are spaced evenly around the whole ellipse, so operators ride the full
    /// circle instead of bunching along the bottom.
    private var spread: Double {
        guard offers.count > 1 else { return 360 }
        return 360 / Double(offers.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { proxy in
                let size = proxy.size
                let center = CGPoint(x: size.width / 2, y: size.height * 0.52)
                let radii = CGSize(width: size.width * 0.465, height: size.height * 0.29)

                ZStack {
                    aura(center: center, radii: radii)

                    ring(center: center, radii: radii, isFront: false)

                    // Nodes on the far side of the orbit pass behind the die.
                    ForEach(backNodes, id: \.offer.id) { entry in
                        node(for: entry, center: center, radii: radii)
                    }

                    die(size: size)

                    ring(center: center, radii: radii, isFront: true)

                    ForEach(frontNodes, id: \.offer.id) { entry in
                        node(for: entry, center: center, radii: radii)
                    }
                }
                .frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .gesture(swipe)
            }
            .frame(height: 392)

            swipeHint
        }
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

    /// Half of the orbit, rendered like a planetary ring: a soft outer halo, a
    /// solid gold band, and a bright inner filament, with the front half heavier
    /// than the back so the band reads as a flat disc tilted in space.
    private func ring(center: CGPoint, radii: CGSize, isFront: Bool) -> some View {
        let rect = CGRect(
            x: center.x - radii.width,
            y: center.y - radii.height,
            width: radii.width * 2,
            height: radii.height * 2
        )
        let sweepStart = sweepAnchor
        let weight: Double = isFront ? 1 : 0.52

        return ZStack {
            // Wide, very soft halo: the light the ring casts into the canvas.
            OrbitArc(rect: rect, isFront: isFront)
                .stroke(
                    BBTheme.gold.opacity(0.26 * weight),
                    style: .init(lineWidth: 16, lineCap: .round)
                )
                .blur(radius: 16)

            // Mid bloom, tighter and brighter.
            OrbitArc(rect: rect, isFront: isFront)
                .stroke(
                    BBTheme.gold.opacity(0.4 * weight),
                    style: .init(lineWidth: 7, lineCap: .round)
                )
                .blur(radius: 6)

            // The band itself.
            OrbitArc(rect: rect, isFront: isFront)
                .stroke(
                    BBTheme.goldSweep,
                    style: .init(lineWidth: isFront ? 3.4 : 2, lineCap: .round)
                )
                .opacity(isFront ? 0.98 : 0.55)

            // Hot filament down the middle of the band gives it its metallic edge.
            OrbitArc(rect: rect, isFront: isFront)
                .stroke(
                    BBTheme.goldBright.opacity(isFront ? 0.85 : 0.35),
                    style: .init(lineWidth: isFront ? 1.1 : 0.7, lineCap: .round)
                )

            // Traveling highlight: sits under the focused node and follows the swipe.
            OrbitArc(rect: rect, isFront: isFront)
                .trim(from: sweepStart, to: sweepStart + 0.16)
                .stroke(
                    LinearGradient(
                        colors: [.clear, BBTheme.goldBright, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: .init(lineWidth: isFront ? 5 : 3, lineCap: .round)
                )
                .opacity(isFront ? 1 : 0.4)
                .blur(radius: isFront ? 1.5 : 2.5)
                .shadow(color: BBTheme.gold.opacity(0.75), radius: 11)
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
        let side = min(size.width * 0.54, 210)
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
        let depth = depth(of: entry)
        let point = CGPoint(
            x: center.x + radii.width * cos(angle.radians),
            y: center.y + radii.height * depth
        )
        .rotated(around: center, by: .degrees(ringTilt))
        let normalizedDepth = (depth + 1) / 2
        let scale = 0.5 + 0.5 * normalizedDepth
        let isFocused = entry.isFocused

        return JourneyOrbitNode(
            offer: entry.offer,
            isFocused: isFocused,
            // Every rider is named — with only six stops on the ring the labels
            // stay readable, and they match the reference layout.
            showsLabel: true,
            action: { onNodeTap(entry.offer.id) }
        )
        .scaleEffect(scale)
        .opacity(0.22 + 0.78 * normalizedDepth)
        .blur(radius: isFocused ? 0 : (1 - normalizedDepth) * 2.6)
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

    // MARK: - Nodes

    private struct OrbitNode {
        let index: Int
        let offer: JourneyOffer
        let isFocused: Bool
    }

    /// Every offer rides the ring at once. Because the spacing divides 360 degrees
    /// exactly, the layout repeats every full lap, so the orbit can spin forever in
    /// either direction without any node popping in or out.
    private var allNodes: [OrbitNode] {
        let count = offers.count
        guard count > 0 else { return [] }
        let focused = ((focusIndex % count) + count) % count
        return offers.enumerated().map { item in
            OrbitNode(index: item.offset, offer: item.element, isFocused: item.offset == focused)
        }
    }

    private var backNodes: [OrbitNode] { visibleNodes.filter { depth(of: $0) < 0 } }

    private var frontNodes: [OrbitNode] { visibleNodes.filter { depth(of: $0) >= 0 } }

    /// The six operators closest to the front of the ring. As the orbit turns, a
    /// stop slips off the far edge and the next one slips in behind the die, so
    /// the ring always carries exactly six stops without any popping up front.
    private var visibleNodes: [OrbitNode] {
        let count = offers.count
        guard count > 0 else { return [] }
        return allNodes
            .map { entry -> (OrbitNode, Double) in
                let raw = (Double(entry.index) - phase) * spread
                let wrapped = raw.truncatingRemainder(dividingBy: 360)
                let normalized = wrapped < 0 ? wrapped + 360 : wrapped
                return (entry, min(normalized, 360 - normalized))
            }
            .sorted { $0.1 < $1.1 }
            .prefix(6)
            .map { $0.0 }
    }

    /// -1 at the back of the orbit, +1 at the front.
    private func depth(of entry: OrbitNode) -> Double {
        sin(Angle.degrees(90 + (Double(entry.index) - phase) * spread).radians)
    }
}

// MARK: - Node

/// A single operator riding the orbit: rank, brand tile, name, and journey state.
private struct JourneyOrbitNode: View {
    let offer: JourneyOffer
    let isFocused: Bool
    let showsLabel: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            VStack(spacing: 6) {
                if offer.state == .next {
                    Text("Next")
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
                            Text(offer.mark.monogram)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .foregroundStyle(Color(rgb: offer.mark.ink))
                                .padding(6)
                        }
                        // Locked stops get a frosted veil drawn over the logo, so the
                        // eye is pulled to the stop the player can actually play next.
                        .overlay { if isLocked { lockVeil } }
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(
                                isFocused ? BBTheme.gold : BBTheme.hairline.opacity(isLocked ? 0.35 : 0.7),
                                lineWidth: isFocused ? 2.4 : 1
                            )
                        }
                        .shadow(
                            color: BBTheme.canvasDeep.opacity(isLocked ? 0.3 : 0.6),
                            radius: 8,
                            y: 4
                        )

                    if isFocused {
                        Circle()
                            .stroke(BBTheme.gold.opacity(0.35), lineWidth: 8)
                            .blur(radius: 5)
                    }
                }
                .frame(width: 62, height: 62)
                .overlay(alignment: .topLeading) { if !isLocked { rankBadge } }
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
                        .foregroundStyle(stateTint)
                }
                .frame(width: 104)
                .opacity(showsLabel ? 1 : 0)
                .animation(.easeOut(duration: 0.18), value: showsLabel)
            }
        }
        .buttonStyle(BBPressStyle())
        .animation(.spring(response: 0.34, dampingFraction: 0.78), value: isFocused)
        .accessibilityLabel("\(offer.rankLabel): \(offer.name), \(offer.state.trailLabel)")
        .accessibilityAddTraits(isFocused ? [.isSelected] : [])
    }

    private var isLocked: Bool { offer.isLockedOnOrbit && !isFocused }

    /// Frosted wrap over a not-yet-available logo: a canvas-toned gradient that
    /// thins toward the top, plus a small lock or trophy glyph.
    private var lockVeil: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BBTheme.canvas.opacity(0.74),
                    BBTheme.canvasDeep.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Image(systemName: offer.state == .ready ? "trophy" : "lock.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(BBTheme.inkMuted.opacity(0.85))
        }
    }

    private var stateTint: Color {
        if isFocused { return BBTheme.gold }
        switch offer.state {
        case .completed: return BBTheme.positive.opacity(0.85)
        case .next: return BBTheme.gold.opacity(0.85)
        case .current, .ready, .future: return BBTheme.inkMuted.opacity(0.7)
        }
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

// MARK: - Geometry helper

private extension CGPoint {
    /// Rotates the point around `origin`, matching `rotationEffect` so orbit
    /// nodes ride the same tilted plane as the ring stroke.
    func rotated(around origin: CGPoint, by angle: Angle) -> CGPoint {
        let dx = x - origin.x
        let dy = y - origin.y
        let cosA = cos(angle.radians)
        let sinA = sin(angle.radians)
        return CGPoint(
            x: origin.x + dx * cosA - dy * sinA,
            y: origin.y + dx * sinA + dy * cosA
        )
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
