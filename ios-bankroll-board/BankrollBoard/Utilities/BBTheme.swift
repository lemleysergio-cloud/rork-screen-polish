//
//  BBTheme.swift
//  BankrollBoard
//

import SwiftUI

/// Central design tokens for the Bankroll Board brand.
/// Deep forest canvas, elevated card surfaces, warm gold accent, editorial serif headlines.
enum BBTheme {
    // MARK: - Color

    static let canvas = Color(red: 0.086, green: 0.141, blue: 0.110)        // #16241C
    static let canvasDeep = Color(red: 0.055, green: 0.098, blue: 0.075)    // #0E1913
    static let surface = Color(red: 0.118, green: 0.180, blue: 0.141)       // #1E2E24
    static let surfaceRaised = Color(red: 0.145, green: 0.216, blue: 0.169) // #25372B
    static let hairline = Color(red: 0.227, green: 0.294, blue: 0.247)      // #3A4B3F
    static let gold = Color(red: 0.851, green: 0.761, blue: 0.478)          // #D9C27A
    static let goldSoft = Color(red: 0.851, green: 0.761, blue: 0.478).opacity(0.14)
    static let ink = Color(red: 0.953, green: 0.945, blue: 0.906)           // #F3F1E7
    static let inkMuted = Color(red: 0.663, green: 0.722, blue: 0.675)      // #A9B8AC
    static let goldDeep = Color(red: 0.604, green: 0.475, blue: 0.161)      // #9A7929
    static let goldBright = Color(red: 0.976, green: 0.855, blue: 0.518)    // #F9DA84
    static let positive = Color(red: 0.694, green: 0.847, blue: 0.529)      // #B1D887

    /// Left-to-right gold sweep used on the journey orbit and progress fills.
    static let goldSweep = LinearGradient(
        colors: [goldDeep, goldBright, goldBright, goldDeep],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Metrics

    static let screenMargin: CGFloat = 20
    static let cardRadius: CGFloat = 20
    static let cardSpacing: CGFloat = 12
    static let hairlineWidth: CGFloat = 1

    // MARK: - Typography

    /// Editorial serif used for step headlines.
    static func headline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static let eyebrow: Font = .system(size: 12, weight: .semibold)
    static let body: Font = .system(size: 16, weight: .regular)
    static let optionTitle: Font = .system(size: 17, weight: .semibold)
    static let optionSubtitle: Font = .system(size: 14, weight: .regular)
    static let caption: Font = .system(size: 13, weight: .regular)

    /// Tabular serif numerals used on money figures.
    static func money(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
}

// `Color(rgb:opacity:)` lives in `JourneyHeroModels.swift` so there is a single
// hex initializer across the app.

extension View {
    /// Applies the branded canvas gradient behind a screen.
    func bbCanvasBackground() -> some View {
        background(
            LinearGradient(
                colors: [BBTheme.canvas, BBTheme.canvasDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    /// Small-caps, wide-tracked gold label used above headlines.
    func bbEyebrowStyle() -> some View {
        font(BBTheme.eyebrow)
            .textCase(.uppercase)
            .kerning(1.6)
            .foregroundStyle(BBTheme.gold)
    }
}
