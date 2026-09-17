//
//  JourneyHeroOrbitView.swift
//  BankrollBoard
//
//  Five-slot Journey orbit selector: fixed node positions, layered gold ellipse,
//  and the tumbling die between the back and front arcs.
//

import SwiftUI
import UIKit

struct JourneyOrbitView: View {
    @ObservedObject var viewModel: JourneyOrbitViewModel
    var onOpenCasino: (JourneyCasino) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tumbleToken = 0
    @State private var strongTumble = false
    @State private var ringPulse = false

    private let slotPositions: [CGPoint] = [
        .init(x: 0.12, y: 0.29),
        .init(x: 0.17, y: 0.72),
        .init(x: 0.50, y: 0.77),
        .init(x: 0.82, y: 0.67),
        .init(x: 0.89, y: 0.31)
    ]

    var body: some View {
        VStack(spacing: 0) {
            orbitCanvas
            caption
        }
        // The gold fade spans the ring and the caption together, so the caption
        // reads as part of the glow instead of sitting outside it.
        .background(alignment: .bottom) {
            RadialGradient(
                colors: [JourneyPalette.gold.opacity(0.13), JourneyPalette.gold.opacity(0.05), .clear],
                center: UnitPoint(x: 0.50, y: 0.62),
                startRadius: 5,
                endRadius: 250
            )
            .allowsHitTesting(false)
        }
    }

    /// Tucked just under the NEXT pill, inside the hero's gold fade.
    private var caption: some View {
        VStack(spacing: 3) {
            HStack(spacing: 6) {
                Text("←").foregroundColor(JourneyPalette.gold)
                Text("Swipe to explore")
                Text("→").foregroundColor(JourneyPalette.gold)
            }
            .font(.system(size: 10, weight: .bold))

            Text("Best-offer rank · #1 first")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(JourneyPalette.muted)
        // Negative inset closes the empty gap under the NEXT pill.
        .padding(.top, -20)
        .padding(.bottom, 4)
        .allowsHitTesting(false)
    }

    private var orbitCanvas: some View {
        GeometryReader { proxy in
            ZStack {
                selectorBackground

                JourneyBackOrbit(pulsing: ringPulse)
                    .frame(width: proxy.size.width + 64, height: proxy.size.height - 94)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2 + 1)
                    .zIndex(1)

                JourneyDiceView(tumbleToken: tumbleToken, strongTumble: strongTumble)
                    .position(x: proxy.size.width * 0.50, y: proxy.size.height * 0.42)
                    .zIndex(4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Tumble the Journey die")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { tumble() }

                JourneyFrontOrbit(pulsing: ringPulse)
                    .frame(width: proxy.size.width + 64, height: proxy.size.height - 94)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2 + 1)
                    .zIndex(5)
                    .allowsHitTesting(false)

                ForEach(viewModel.visibleNodes) { node in
                    if slotPositions.indices.contains(node.slot) {
                        JourneyCasinoNodeView(node: node)
                            .position(
                                x: proxy.size.width * slotPositions[node.slot].x,
                                y: proxy.size.height * slotPositions[node.slot].y
                            )
                            .zIndex(node.relativeOffset == 0 ? 8 : 6)
                            .transition(.opacity.combined(with: .scale(scale: 0.88)))
                    }
                }

                // Horizontal-only pan layer: vertical drags fail immediately so the
                // page keeps scrolling even when the touch starts on the ring.
                JourneyOrbitGestureLayer(
                    onHorizontalSwipe: { move(by: $0) },
                    onTap: { handleTap(at: $0, in: proxy.size) }
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
                .zIndex(10)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Interactive Journey offer selector")
            .accessibilityValue(accessibilityValue)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: move(by: 1)
                case .decrement: move(by: -1)
                @unknown default: break
                }
            }
        }
        .frame(height: 382)
        .clipped()
    }

    private var selectorBackground: some View {
        ZStack {
            RadialGradient(
                colors: [Color(rgb: 0x48674E, opacity: 0.31), .clear],
                center: UnitPoint(x: 0.50, y: 0.45),
                startRadius: 4,
                endRadius: 145
            )
        }
        .allowsHitTesting(false)
    }

    /// Routes a tap on the orbit layer to the nearest casino stop, or rolls the die.
    private func handleTap(at point: CGPoint, in size: CGSize) {
        let hit = viewModel.visibleNodes
            .filter { slotPositions.indices.contains($0.slot) }
            .compactMap { node -> (node: JourneyVisibleNode, distance: CGFloat)? in
                let slot = slotPositions[node.slot]
                let center = CGPoint(x: size.width * slot.x, y: size.height * slot.y)
                let dx = point.x - center.x
                let dy = point.y - center.y
                guard abs(dx) <= 46, abs(dy) <= 50 else { return nil }
                return (node, dx * dx + dy * dy)
            }
            .min { $0.distance < $1.distance }?
            .node

        if let hit {
            select(hit)
        } else {
            tumble()
        }
    }

    private var accessibilityValue: String {
        guard let casino = viewModel.focusedCasino else { return "No offers" }
        return "\(casino.name), rank \(viewModel.focusIndex + 1) of \(viewModel.casinos.count)"
    }

    private func move(by delta: Int) {
        withAnimation(reduceMotion ? nil : .timingCurve(0.2, 0.8, 0.25, 1, duration: 0.38)) {
            viewModel.move(by: delta)
        }
        tumble()
    }

    private func select(_ node: JourneyVisibleNode) {
        withAnimation(reduceMotion ? nil : .timingCurve(0.2, 0.8, 0.25, 1, duration: 0.38)) {
            viewModel.focus(operatorId: node.casino.operatorId)
        }
        tumble()

        let delay = reduceMotion ? 0.05 : 0.58
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            onOpenCasino(node.casino)
        }
    }

    private func tumble(strong: Bool = false) {
        strongTumble = strong
        tumbleToken += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        guard !reduceMotion else { return }
        ringPulse = false
        withAnimation(.easeOut(duration: strong ? 1.38 : 0.58)) {
            ringPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (strong ? 1.38 : 0.58)) {
            ringPulse = false
        }
    }
}

/// Transparent touch layer above the orbit.
///
/// A plain SwiftUI `DragGesture` competes with the enclosing `ScrollView` and
/// swallows vertical drags that start on the ring. This UIKit layer instead uses a
/// pan recognizer that fails as soon as a drag is more vertical than horizontal,
/// and recognizes simultaneously with the scroll view, so up/down swipes always
/// scroll the page while sideways swipes still rotate the orbit.
private struct JourneyOrbitGestureLayer: UIViewRepresentable {
    let onHorizontalSwipe: (Int) -> Void
    let onTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = false

        let pan = HorizontalPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.delegate = context.coordinator
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onHorizontalSwipe = onHorizontalSwipe
        context.coordinator.onTap = onTap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onHorizontalSwipe: onHorizontalSwipe, onTap: onTap)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onHorizontalSwipe: (Int) -> Void
        var onTap: (CGPoint) -> Void

        init(onHorizontalSwipe: @escaping (Int) -> Void, onTap: @escaping (CGPoint) -> Void) {
            self.onHorizontalSwipe = onHorizontalSwipe
            self.onTap = onTap
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            let translation = recognizer.translation(in: recognizer.view)
            guard abs(translation.x) >= 32, abs(translation.x) > abs(translation.y) else { return }
            onHorizontalSwipe(translation.x < 0 ? 1 : -1)
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view else { return }
            onTap(recognizer.location(in: view))
        }

        /// Never block the scroll view's own pan recognizer.
        nonisolated func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

/// Pan recognizer that gives up the moment a drag leans vertical.
private final class HorizontalPanGestureRecognizer: UIPanGestureRecognizer {
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard state == .began || state == .changed else { return }
        let translation = translation(in: view)
        if abs(translation.y) > abs(translation.x) {
            state = .failed
        }
    }
}

private struct JourneyCasinoNodeView: View {
    let node: JourneyVisibleNode

    private var isFocused: Bool { node.relativeOffset == 0 }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if isFocused {
                    selectedBadge
                        .offset(y: -48)
                }

                Circle()
                    .fill(JourneyPalette.nodeBackground)
                    .overlay(
                        Circle().stroke(borderColor, lineWidth: isFocused ? 3 : 2.5)
                    )
                    .shadow(color: glowColor, radius: isFocused ? 15 : 7)
                    .shadow(color: .black.opacity(0.42), radius: 10, x: 0, y: 8)
                    .frame(width: isFocused ? 74 : 58, height: isFocused ? 74 : 58)

                JourneyCasinoLogo(casino: node.casino)
                    .frame(width: isFocused ? 61 : 48, height: isFocused ? 61 : 48)
                    .clipShape(Circle())

                rankBadge
                    .offset(x: isFocused ? -31 : -25, y: isFocused ? -31 : -25)

                stateBadge
                    .offset(x: isFocused ? 31 : 25, y: isFocused ? 31 : 25)
            }
            .frame(width: 82, height: 82)

            Text(displayName)
                .font(.system(size: isFocused ? 13 : 12, weight: .heavy))
                .foregroundColor(isFocused ? Color(rgb: 0xFFF8DF) : Color(rgb: 0xE7ECE8))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 110)
                .shadow(color: .black.opacity(0.65), radius: 3, y: 2)

            Text(node.state.label.uppercased())
                .font(.system(size: 8, weight: .black))
                .foregroundColor(statusColor)
                .padding(.horizontal, node.state == .next ? 9 : 0)
                .padding(.vertical, node.state == .next ? 4 : 0)
                .background(
                    Group {
                        if node.state == .next {
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Color(rgb: 0xF1D46A), Color(rgb: 0xB88D1F)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                    }
                )
        }
        .frame(width: 118)
        .opacity(node.state == .locked && !isFocused ? 0.38 : 1)
        .saturation(node.state == .locked && !isFocused ? 0.35 : 1)
        .scaleEffect(isFocused ? 1 : 0.98)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Best offer rank \(node.rank): \(node.casino.name), \(isFocused ? "selected, " : "")\(node.state.label)")
        .accessibilityHint("Double tap to preview offer details")
        .accessibilityAddTraits(.isButton)
    }

    private var displayName: String {
        node.casino.name.replacingOccurrences(of: " Casino", with: "")
    }

    private var borderColor: Color {
        if isFocused { return Color(rgb: 0xFFE184) }
        switch node.state {
        case .completed: return JourneyPalette.success
        case .current, .active, .next: return Color(rgb: 0xE7C75D)
        case .locked: return JourneyPalette.gold.opacity(0.48)
        }
    }

    private var glowColor: Color {
        if isFocused { return Color(rgb: 0xE8BE3D, opacity: 0.74) }
        if node.state == .completed { return JourneyPalette.success.opacity(0.28) }
        return .black.opacity(0.22)
    }

    private var statusColor: Color {
        switch node.state {
        case .completed: return JourneyPalette.success
        case .next: return Color(rgb: 0x1A281E)
        default: return JourneyPalette.gold
        }
    }

    private var selectedBadge: some View {
        Text("SELECTED")
            .font(.system(size: 8, weight: .black))
            .foregroundColor(Color(rgb: 0x17271C))
            .padding(.horizontal, 10)
            .frame(height: 20)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [Color(rgb: 0xF5DC79), Color(rgb: 0xC79827)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(Capsule().stroke(Color(rgb: 0xFFE98B, opacity: 0.8), lineWidth: 1))
            .shadow(color: .black.opacity(0.34), radius: 7, y: 4)
    }

    private var rankBadge: some View {
        Text("\(node.rank)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(Color(rgb: 0xF8E8B2))
            .frame(minWidth: 23, minHeight: 23)
            .background(Circle().fill(Color(rgb: 0x233A2B)))
            .overlay(Circle().stroke(Color(rgb: 0xE6C775), lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
    }

    @ViewBuilder
    private var stateBadge: some View {
        if node.state == .completed || node.state == .locked {
            Text(node.state == .completed ? "✓" : "•")
                .font(.system(size: node.state == .completed ? 13 : 9, weight: .black))
                .foregroundColor(Color(rgb: 0x19281E))
                .frame(width: 23, height: 23)
                .background(Circle().fill(node.state == .completed ? JourneyPalette.success : Color(rgb: 0x33483A)))
                .overlay(Circle().stroke(Color(rgb: 0x17271C), lineWidth: 2))
        }
    }
}

private struct JourneyCasinoLogo: View {
    let casino: JourneyCasino

    var body: some View {
        ZStack {
            Color(rgb: 0xF5F3EB)
            if let name = casino.logoAssetName, let image = UIImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(2)
            } else {
                Text(initials)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(rgb: casino.brandColorHex))
            }
        }
    }

    private var initials: String {
        casino.name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

private struct JourneyBackOrbit: View {
    let pulsing: Bool

    var body: some View {
        ZStack {
            JourneyOrbitEllipse()
                .stroke(JourneyPalette.gold.opacity(0.11), lineWidth: 8)
                .blur(radius: 5)

            JourneyOrbitEllipse()
                .stroke(
                    LinearGradient(
                        colors: [Color(rgb: 0x9A7929), Color(rgb: 0xF4D77A), Color(rgb: 0xFFD976), Color(rgb: 0x8D7129)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2.2
                )

            JourneyOrbitEllipse()
                .trim(from: pulsing ? 0.62 : 0.10, to: pulsing ? 0.96 : 0.22)
                .stroke(Color(rgb: 0xFFF2A6), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .blur(radius: 1.5)
                .opacity(pulsing ? 0 : 0.9)
                .animation(.easeOut(duration: 0.58), value: pulsing)
        }
        .rotationEffect(.degrees(-5))
    }
}

private struct JourneyFrontOrbit: View {
    let pulsing: Bool

    var body: some View {
        ZStack {
            JourneyFrontArc()
                .stroke(JourneyPalette.gold.opacity(0.17), lineWidth: 8)
                .blur(radius: 5)

            JourneyFrontArc()
                .stroke(
                    LinearGradient(
                        colors: [Color(rgb: 0xB18C31), Color(rgb: 0xF8DE84), Color(rgb: 0xFFE18A), Color(rgb: 0xA07D2D)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2.8
                )

            JourneyFrontArc()
                .trim(from: pulsing ? 0.50 : 0.04, to: pulsing ? 0.94 : 0.20)
                .stroke(Color(rgb: 0xFFF0AE), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .shadow(color: Color(rgb: 0xFFE070, opacity: 0.9), radius: 6)
                .opacity(pulsing ? 0 : 1)
                .animation(.easeOut(duration: 0.58), value: pulsing)
        }
        .rotationEffect(.degrees(-5))
    }
}

private struct JourneyOrbitEllipse: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect.insetBy(dx: rect.width * 0.062, dy: rect.height * 0.15))
        return path
    }
}

private struct JourneyFrontArc: Shape {
    func path(in rect: CGRect) -> Path {
        let ellipse = rect.insetBy(dx: rect.width * 0.062, dy: rect.height * 0.15)
        let center = CGPoint(x: ellipse.midX, y: ellipse.midY)
        let radiusX = ellipse.width / 2
        let radiusY = ellipse.height / 2
        var path = Path()

        for step in 0...96 {
            let theta = Double.pi * Double(step) / 96
            let point = CGPoint(
                x: center.x + radiusX * CGFloat(cos(theta)),
                y: center.y + radiusY * CGFloat(sin(theta))
            )
            if step == 0 { path.move(to: point) }
            else { path.addLine(to: point) }
        }
        return path
    }
}

enum JourneyPalette {
    static let canvas = Color(rgb: 0x10251A)
    static let canvasDeep = Color(rgb: 0x08150F)
    static let panel = Color(rgb: 0x171B21)
    static let nodeBackground = Color(rgb: 0x1C2E22)
    static let gold = Color(rgb: 0xD4AF37)
    static let muted = Color(rgb: 0x91A398)
    static let ink = Color(rgb: 0xF4F1E8)
    static let success = Color(rgb: 0x8DC63F)
}
