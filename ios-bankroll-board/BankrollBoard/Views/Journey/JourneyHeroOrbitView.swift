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
    @State private var dragStarted = false

    private let slotPositions: [CGPoint] = [
        .init(x: 0.12, y: 0.29),
        .init(x: 0.17, y: 0.72),
        .init(x: 0.50, y: 0.77),
        .init(x: 0.82, y: 0.67),
        .init(x: 0.89, y: 0.31)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                selectorBackground

                JourneyBackOrbit(pulsing: ringPulse)
                    .frame(width: proxy.size.width + 64, height: proxy.size.height - 94)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2 + 1)
                    .zIndex(1)
                    .onTapGesture { tumble() }

                JourneyDiceView(tumbleToken: tumbleToken, strongTumble: strongTumble)
                    .position(x: proxy.size.width * 0.50, y: proxy.size.height * 0.42)
                    .zIndex(4)
                    .onTapGesture { tumble() }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Tumble the Journey die")
                    .accessibilityAddTraits(.isButton)

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
                            .onTapGesture { select(node) }
                    }
                }

                VStack(spacing: 4) {
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
                .position(x: proxy.size.width / 2, y: proxy.size.height - 18)
                .zIndex(9)
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(swipeGesture)
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
            RadialGradient(
                colors: [JourneyPalette.gold.opacity(0.11), .clear],
                center: UnitPoint(x: 0.50, y: 0.70),
                startRadius: 5,
                endRadius: 230
            )
        }
        .allowsHitTesting(false)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { _ in dragStarted = true }
            .onEnded { value in
                defer { dragStarted = false }
                let x = value.translation.width
                let y = value.translation.height
                guard abs(x) >= 32, abs(x) >= abs(y) * 1.2 else { return }
                move(by: x < 0 ? 1 : -1)
            }
    }

    private var accessibilityValue: String {
        guard let casino = viewModel.focusedCasino else { return "No offers" }
        return "\(casino.name), rank \(viewModel.focusIndex + 1) of \(viewModel.casinos.count)"
    }

    private func move(by delta: Int) {
        guard !dragStarted || delta != 0 else { return }
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
