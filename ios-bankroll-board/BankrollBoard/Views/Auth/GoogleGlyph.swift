//
//  GoogleGlyph.swift
//  BankrollBoard
//

import SwiftUI

/// Four-colour "G" drawn natively so it stays crisp at any size.
struct GoogleGlyph: View {
    private static let blue = Color(rgb: 0x4285F4)
    private static let green = Color(rgb: 0x34A853)
    private static let yellow = Color(rgb: 0xFBBC05)
    private static let red = Color(rgb: 0xEA4335)

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let line = side * 0.21
            ZStack {
                // Trim runs clockwise from 3 o'clock; the gap sits top-right.
                arc(from: 0.0, to: 0.13, color: Self.blue, line: line)
                arc(from: 0.125, to: 0.38, color: Self.green, line: line)
                arc(from: 0.375, to: 0.565, color: Self.yellow, line: line)
                arc(from: 0.56, to: 0.875, color: Self.red, line: line)
                Rectangle()
                    .fill(Self.blue)
                    .frame(width: side * 0.5, height: line)
                    .offset(x: side * 0.25)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }

    private func arc(from start: CGFloat, to end: CGFloat, color: Color, line: CGFloat) -> some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .butt))
            .padding(line / 2)
    }
}

#Preview {
    GoogleGlyph()
        .frame(width: 80, height: 80)
        .padding()
}
