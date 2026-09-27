//
//  HomePalette.swift
//  BankrollBoard
//
//  Every colour the Home tab uses lives here, in two looks:
//
//    • cream  — paper gradient around #F9F4EA, matching the sign-in screen
//    • forest — the original deep-green Home
//
//  Switch between them in the app under Settings → Appearance, or change
//  `HomeStyle.defaultStyle` below to pick what new installs see.
//  To tweak the cream look, edit the values in `HomePalette.cream`.
//
//  Only Home (and its chart / pending screens) read this. Stats, Journey,
//  Community and Settings keep the forest look no matter which is chosen.
//

import SwiftUI

nonisolated enum HomeStyle: String, CaseIterable, Identifiable, Sendable {
    case cream
    case forest

    /// What Home looks like until the user picks otherwise.
    /// Change to `.forest` to bring back the original dark Home by default.
    static let defaultStyle: HomeStyle = .cream

    /// UserDefaults key for the Settings → Appearance choice.
    static let storageKey: String = "bb.homeStyle"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cream: "Cream"
        case .forest: "Forest"
        }
    }

    var palette: HomePalette {
        switch self {
        case .cream: .cream
        case .forest: .forest
        }
    }
}

nonisolated struct HomePalette: Sendable {
    let colorScheme: ColorScheme

    // Background
    let backgroundColors: [Color]
    /// Soft light bloom near the top of the screen.
    let topGlow: Color
    /// Warm gold haze in the bottom-right corner.
    let cornerGlow: Color

    // Text
    let ink: Color
    let inkMuted: Color

    // Lines and surfaces
    let hairline: Color
    /// Subtle fill behind chips and tiles.
    let surface: Color
    /// Recessed track behind the timeframe control.
    let track: Color
    /// Pinned bottom bar behind sheet actions.
    let barFill: Color

    // Accents
    /// Links, kickers, icons, active outlines.
    let accent: Color
    /// Text on the active timeframe.
    let accentBright: Color
    /// Solid fill for the selected chip and primary buttons.
    let accentFill: Color
    /// Text on `accentFill`.
    let onAccentFill: Color

    // Money
    let positive: Color
    let negative: Color
    let warning: Color

    // Chart
    let chartLine: [Color]
    let chartGlow: Color
    let chartDot: Color
    let scrubDot: Color
    let gridLine: Color
    let calloutFill: Color
    let shadow: Color

    private static func hex(_ value: UInt32, _ opacity: Double = 1) -> Color {
        Color(
            .sRGB,
            red: Double((value >> 16) & 0xff) / 255,
            green: Double((value >> 8) & 0xff) / 255,
            blue: Double(value & 0xff) / 255,
            opacity: opacity
        )
    }

    /// Paper-toned Home that matches the sign-in screen.
    static let cream = HomePalette(
        colorScheme: .light,
        backgroundColors: [hex(0xFDFAF4), hex(0xF9F4EA), hex(0xF2E9D8)],
        topGlow: hex(0xFFFFFF, 0.8),
        cornerGlow: hex(0xD4AF37, 0.1),
        ink: hex(0x10251A),
        inkMuted: hex(0x6E7B70),
        hairline: hex(0xDCCFB8),
        surface: hex(0xFFFFFF, 0.62),
        track: hex(0xEFE5D2, 0.85),
        barFill: hex(0xF9F4EA, 0.96),
        accent: hex(0x9A7929),
        accentBright: hex(0x7A5E1C),
        accentFill: hex(0x10251A),
        onAccentFill: hex(0xF9F4EA),
        positive: hex(0x2F7D4F),
        negative: hex(0xB5483C),
        warning: hex(0xB7772A),
        chartLine: [hex(0x9A7929), hex(0xD4AF37), hex(0xD4AF37), hex(0x9A7929)],
        chartGlow: hex(0xD4AF37),
        chartDot: hex(0xC9A23A),
        scrubDot: hex(0xFFFFFF),
        gridLine: hex(0x10251A, 0.07),
        calloutFill: hex(0xFFFFFF, 0.97),
        shadow: hex(0x10251A, 0.12)
    )

    /// The original deep-green Home.
    static let forest = HomePalette(
        colorScheme: .dark,
        backgroundColors: [hex(0x08150F), hex(0x10251A), hex(0x132F20)],
        topGlow: .clear,
        cornerGlow: .clear,
        ink: hex(0xF3F1E7),
        inkMuted: hex(0xA9B8AC),
        hairline: hex(0x3A4B3F),
        surface: hex(0xFFFFFF, 0.05),
        track: hex(0x000000, 0.16),
        barFill: hex(0x08150F, 0.94),
        accent: hex(0xD9C27A),
        accentBright: hex(0xF9DA84),
        accentFill: hex(0xD9C27A),
        onAccentFill: hex(0x08150F),
        positive: hex(0xB1D887),
        negative: hex(0xE2928A),
        warning: hex(0xE2A25A),
        chartLine: [hex(0x9A7929), hex(0xF9DA84), hex(0xF9DA84), hex(0x9A7929)],
        chartGlow: hex(0xD9C27A),
        chartDot: hex(0xF9DA84),
        scrubDot: hex(0xF3F1E7),
        gridLine: hex(0xFFFFFF, 0.07),
        calloutFill: hex(0x0E1913, 0.96),
        shadow: hex(0x000000, 0.4)
    )
}

nonisolated private struct HomePaletteKey: EnvironmentKey {
    static let defaultValue: HomePalette = .forest
}

extension EnvironmentValues {
    /// Colours for Home. Defaults to forest so shared pieces (timeframe bar,
    /// activity rows) keep their dark look on Stats.
    var homePalette: HomePalette {
        get { self[HomePaletteKey.self] }
        set { self[HomePaletteKey.self] = newValue }
    }
}

/// Layered gradient behind Home: base wash, top bloom, gold corner haze.
struct HomeBackdrop: View {
    @Environment(\.homePalette) private var palette

    var body: some View {
        ZStack {
            LinearGradient(
                colors: palette.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [palette.topGlow, palette.topGlow.opacity(0)],
                center: UnitPoint(x: 0.5, y: 0.06),
                startRadius: 0,
                endRadius: 360
            )
            RadialGradient(
                colors: [palette.cornerGlow, palette.cornerGlow.opacity(0)],
                center: UnitPoint(x: 0.95, y: 1.0),
                startRadius: 0,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Wide-tracked uppercase kicker in the Home accent colour.
    func homeEyebrowStyle(_ palette: HomePalette) -> some View {
        font(BBTheme.eyebrow)
            .textCase(.uppercase)
            .kerning(1.6)
            .foregroundStyle(palette.accent)
    }
}
