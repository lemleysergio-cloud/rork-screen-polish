//
//  AuthProviderButton.swift
//  BankrollBoard
//

import SwiftUI

/// Outlined "Continue with …" button with a leading brand glyph.
struct AuthProviderButton<Icon: View>: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    private let icon: Icon

    init(
        title: String,
        isLoading: Bool,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
        self.icon = icon()
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                HStack(spacing: 12) {
                    icon
                        .frame(width: 22, height: 22)
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
                .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(AuthPalette.ink)
                }
            }
            .foregroundStyle(AuthPalette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.55))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AuthPalette.hairline, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(BBPressStyle())
    }
}
