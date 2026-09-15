//
//  Haptics.swift
//  BankrollBoard
//

import UIKit

/// Centralized haptic feedback so all tappable surfaces feel consistent.
enum Haptics {
    /// Light tick for toggling an option or picking a row.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Soft impact for primary button taps and step transitions.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Success notification for correct practice answers and completion.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning notification for incorrect practice answers.
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
