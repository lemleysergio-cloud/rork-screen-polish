//
//  QuickSignInButton.swift
//  BankrollBoard
//
//  "Welcome back" card on the login screen for returning users who turned
//  on Face ID sign-in: shows the remembered account and a one-tap unlock.
//

import SwiftUI

struct QuickSignInButton: View {
    let account: RememberedAccount
    let kind: BiometricKind
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AuthPalette.forestLight, AuthPalette.forest],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    if isLoading {
                        ProgressView()
                            .tint(AuthPalette.gold)
                    } else {
                        Image(systemName: kind.symbol)
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(AuthPalette.gold)
                    }
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Sign in with \(kind.title)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AuthPalette.ink)
                    Text(account.maskedName)
                        .font(.system(size: 14))
                        .foregroundStyle(AuthPalette.inkMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AuthPalette.inkMuted.opacity(0.7))
            }
            .padding(12)
            .padding(.trailing, 6)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.7))
                    .shadow(color: AuthPalette.forest.opacity(0.08), radius: 14, y: 6)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(AuthPalette.gold.opacity(0.45), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(BBPressStyle())
        .accessibilityLabel("Sign in with \(kind.title) as \(account.displayName)")
        .accessibilityIdentifier("auth.faceID")
    }
}

#Preview {
    QuickSignInButton(
        account: RememberedAccount(provider: .email, email: "jordan@gmail.com"),
        kind: .faceID,
        isLoading: false,
        action: {}
    )
    .padding(24)
    .background(AuthPalette.paper)
}
