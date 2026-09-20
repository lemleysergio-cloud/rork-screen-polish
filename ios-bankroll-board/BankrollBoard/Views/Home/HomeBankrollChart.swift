//
//  HomeBankrollChart.swift
//  BankrollBoard
//
//  Gold line chart of cumulative net transfers, with touch-to-inspect scrubbing.
//

import SwiftUI
import UIKit

struct HomeBankrollChart: View {
    let points: [BankrollPoint]
    let timeframe: HomeTimeframe
    /// Horizontal position being inspected, 0...1 across the plot.
    let scrubProgress: Double?
    let onScrub: (Double?) -> Void
    var height: CGFloat = 206
    /// Width reserved for the value axis gutter.
    private let gutter: CGFloat = 52

    private var values: [Double] { points.map { Double($0.cents) } }

    /// Axis ticks derived from the real range, so labels never repeat.
    private var ticks: [Double] {
        guard let low = values.min(), let high = values.max() else { return [] }
        // A dead-flat series still needs a readable band around it.
        if high - low < 1 {
            let pad = max(abs(high) * 0.002, 100)
            return homeNiceTicks(min: low - pad, max: high + pad)
        }
        let padding = (high - low) * 0.12
        return homeNiceTicks(min: low - padding, max: high + padding)
    }

    private var axisStep: Double {
        guard ticks.count > 1 else { return 100 }
        return ticks[1] - ticks[0]
    }

    private var lowerBound: Double { ticks.first ?? 0 }
    private var upperBound: Double { ticks.last ?? 1 }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let plotWidth = max(geo.size.width - gutter, 1)
                let plotHeight = geo.size.height

                ZStack(alignment: .topLeading) {
                    gridAndLabels(plotWidth: plotWidth, plotHeight: plotHeight)

                    if points.count > 1 {
                        areaFill(width: plotWidth, height: plotHeight)
                            .offset(x: gutter)

                        linePath(width: plotWidth, height: plotHeight)
                            .stroke(
                                BBTheme.goldSweep,
                                style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                            )
                            .offset(x: gutter)
                            .shadow(color: BBTheme.gold.opacity(0.35), radius: 7, y: 3)

                        endpointDot(width: plotWidth, height: plotHeight)
                            .offset(x: gutter)

                        if let progress = scrubProgress,
                           let point = homeInterpolatedPoint(points, at: progress) {
                            scrubOverlay(
                                progress: progress,
                                point: point,
                                width: plotWidth,
                                height: plotHeight
                            )
                            .offset(x: gutter)
                        }
                    }

                    HomeChartScrubLayer(
                        onLocation: { location in
                            guard let location else {
                                onScrub(nil)
                                return
                            }
                            onScrub(progress(forX: location.x, width: plotWidth))
                        }
                    )
                    .frame(width: plotWidth, height: plotHeight)
                    .offset(x: gutter)
                }
            }
            .frame(height: height)

            axisDates
                .padding(.leading, gutter)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bankroll over time, \(timeframe.long)")
        .accessibilityValue(accessibilitySummary)
    }

    // MARK: - Geometry

    private func x(for index: Int, width: CGFloat) -> CGFloat {
        guard points.count > 1 else { return 0 }
        return width * CGFloat(index) / CGFloat(points.count - 1)
    }

    private func y(for value: Double, height: CGFloat) -> CGFloat {
        let span = upperBound - lowerBound
        guard span > 0 else { return height / 2 }
        let ratio = (value - lowerBound) / span
        return height - CGFloat(ratio) * height
    }

    /// Touch x within the plot, as a 0...1 fraction of the window.
    ///
    /// Reported continuously rather than rounded to a sample, so the crosshair
    /// tracks the finger exactly instead of snapping between data points.
    private func progress(forX position: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        return Double(min(max(position / width, 0), 1))
    }

    private func linePath(width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            for (index, point) in points.enumerated() {
                let position = CGPoint(
                    x: x(for: index, width: width),
                    y: y(for: Double(point.cents), height: height)
                )
                if index == 0 {
                    path.move(to: position)
                } else {
                    path.addLine(to: position)
                }
            }
        }
    }

    private func areaFill(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: 0, y: height))
            path.addLine(
                to: CGPoint(x: 0, y: y(for: Double(first.cents), height: height))
            )
            for (index, point) in points.enumerated() {
                path.addLine(
                    to: CGPoint(
                        x: x(for: index, width: width),
                        y: y(for: Double(point.cents), height: height)
                    )
                )
            }
            path.addLine(to: CGPoint(x: width, y: height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    BBTheme.gold.opacity(0.26),
                    BBTheme.gold.opacity(0.08),
                    BBTheme.gold.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func endpointDot(width: CGFloat, height: CGFloat) -> some View {
        Group {
            if let last = points.last {
                Circle()
                    .fill(BBTheme.goldBright)
                    .frame(width: 9, height: 9)
                    .shadow(color: BBTheme.gold.opacity(0.6), radius: 5)
                    .position(
                        x: x(for: points.count - 1, width: width),
                        y: y(for: Double(last.cents), height: height)
                    )
            }
        }
    }

    // MARK: - Grid

    private func gridAndLabels(plotWidth: CGFloat, plotHeight: CGFloat) -> some View {
        ForEach(Array(ticks.enumerated()), id: \.offset) { _, tick in
            let position = y(for: tick, height: plotHeight)
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: plotWidth, height: 1)
                    .offset(x: gutter)

                Text(homeAxisLabel(cents: tick, step: axisStep))
                    .font(.system(size: 10))
                    .foregroundStyle(BBTheme.inkMuted.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: gutter - 8, alignment: .trailing)
            }
            .position(x: plotWidth / 2 + gutter / 2, y: position)
        }
    }

    private var axisDates: some View {
        HStack {
            if let first = points.first {
                Text(homeAxisDateLabel(first.date, timeframe: timeframe))
            }
            Spacer(minLength: 0)
            if points.count > 2 {
                Text(homeAxisDateLabel(points[points.count / 2].date, timeframe: timeframe))
                Spacer(minLength: 0)
            }
            if let last = points.last {
                Text(homeAxisDateLabel(last.date, timeframe: timeframe))
            }
        }
        .font(.system(size: 10))
        .foregroundStyle(BBTheme.inkMuted.opacity(0.85))
    }

    // MARK: - Scrub overlay

    private func scrubOverlay(
        progress: Double,
        point: BankrollPoint,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        // Both the line and the dot come from the same fraction, so the marker
        // sits precisely where the finger is on the plotted curve.
        let positionX = width * CGFloat(progress)
        let positionY = y(for: Double(point.cents), height: height)

        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(BBTheme.gold.opacity(0.4))
                .frame(width: 1, height: height)
                .position(x: positionX, y: height / 2)

            Circle()
                .fill(BBTheme.ink)
                .frame(width: 11, height: 11)
                .overlay { Circle().stroke(BBTheme.gold, lineWidth: 2) }
                .position(x: positionX, y: positionY)

            calloutView(point: point)
                .fixedSize()
                .alignmentGuide(.leading) { _ in 0 }
                .position(
                    x: min(max(positionX, 62), width - 62),
                    y: max(positionY - 46, 26)
                )
        }
        .allowsHitTesting(false)
    }

    private func calloutView(point: BankrollPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(homeScrubDateLabel(point.date, timeframe: timeframe))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(BBTheme.inkMuted)
            Text(homeMoney(cents: point.cents, showsPlus: false))
                .font(BBTheme.money(16))
                .foregroundStyle(BBTheme.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 11)
                .fill(BBTheme.canvasDeep.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(BBTheme.hairline, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
        }
    }

    private var accessibilitySummary: String {
        guard let first = points.first, let last = points.last else { return "No data" }
        let change = last.cents - first.cents
        return "\(homeMoney(cents: last.cents, showsPlus: false)), \(homeMoney(cents: change)) over the period"
    }
}

// MARK: - Scrub gesture

/// Transparent touch layer that reports horizontal drags for chart inspection.
///
/// Uses the same approach as the Journey orbit: a pan recognizer that fails as
/// soon as a drag leans vertical, so up/down swipes scroll the page normally
/// while sideways drags inspect the chart.
private struct HomeChartScrubLayer: UIViewRepresentable {
    let onLocation: (CGPoint?) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = false

        let pan = ChartScrubPanRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        // A long press starts inspection without needing sideways movement.
        let press = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePress(_:))
        )
        press.minimumPressDuration = 0.12
        press.delegate = context.coordinator
        view.addGestureRecognizer(press)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onLocation = onLocation
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onLocation: onLocation)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onLocation: (CGPoint?) -> Void

        init(onLocation: @escaping (CGPoint?) -> Void) {
            self.onLocation = onLocation
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            report(state: recognizer.state, location: recognizer.location(in: recognizer.view))
        }

        @objc func handlePress(_ recognizer: UILongPressGestureRecognizer) {
            report(state: recognizer.state, location: recognizer.location(in: recognizer.view))
        }

        private func report(state: UIGestureRecognizer.State, location: CGPoint) {
            switch state {
            case .began, .changed:
                onLocation(location)
            case .ended, .cancelled, .failed:
                onLocation(nil)
            default:
                break
            }
        }

        nonisolated func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

/// Pan recognizer that gives up the moment a drag leans vertical, so the
/// enclosing scroll view keeps ownership of up/down swipes.
private final class ChartScrubPanRecognizer: UIPanGestureRecognizer {
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard state == .began || state == .changed else { return }
        let translation = translation(in: view)
        if abs(translation.y) > abs(translation.x) * 1.4, abs(translation.y) > 12 {
            state = .failed
        }
    }
}
