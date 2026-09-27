//
//  AuthPalette.swift
//  BankrollBoard
//
//  Light, paper-toned palette for the sign-in screen. Ink and accents come
//  from the brand's forest green and gold so it still feels like the app.
//

import SwiftUI

enum AuthPalette {
    static let paper = Color(rgb: 0xF9F4EA)
    static let paperLight = Color(rgb: 0xFDFAF4)
    static let paperDeep = Color(rgb: 0xF2E9D8)
    static let ink = Color(rgb: 0x10251A)
    static let inkMuted = Color(rgb: 0x6E7B70)
    static let hairline = Color(rgb: 0xE2D8C5)
    static let field = Color.white.opacity(0.72)
    static let forest = Color(rgb: 0x10251A)
    static let forestLight = Color(rgb: 0x1C3B29)
    static let gold = Color(rgb: 0xD4AF37)
    static let error = Color(rgb: 0xB5483C)
    static let success = Color(rgb: 0x2F7D4F)
}
