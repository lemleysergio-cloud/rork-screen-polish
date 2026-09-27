//
//  QuickSignInOfferView.swift
//  BankrollBoard
//
//  Shown once after a first sign-in on a Face ID device: invites the user to
//  skip the password next time. "Not now" is remembered.
//

import SwiftUI

struct QuickSignInOfferView: View {
    @Environment(AccountStore.self) private var accounts
    @Environment(\.dismiss) private var dismiss

    @State private var isEnabling: Bool = false
    @State private var errorMessage: String?
    @State private var glyphPulse: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(JourneyPalette.gold.opacity(0.18), lineWidth: 1)
                    .frame(width: 112, height: 112)
                    .scaleEffect(glyphPulse ? 1.08 : 0.94)
                    .opacity(glyphPulse ? 0.4 : 1)
                Circle()
                    .fill(JourneyPalette.gold.opacity(0.1))
                    .frame(width: 88, height: 88)
                Image(systemName: accounts.biometricKind.symbol)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(JourneyPalette.gold)
            }
            .padding(.top, 36)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    glyphPulse = true
                }
            }

            Text("Skip the password next time")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundStyle(JourneyPalette.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 22)

            Text("Use \(accounts.biometricKind.title) to open your board in a glance. You can turn it off anytime in Settings.")
                .font(.system(size: 15))
                .foregroundStyle(BBTheme.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.horizontal, 8)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(rgb: 0xE58B7E))
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)
                    .transition(.opacity)
            }

            Spacer(minLength: 24)

            Button(action: enable) {
                ZStack {
                    Text("Turn On \(accounts.biometricKind.title)")
                        .font(.system(size: 17, weight: .semibold))
                        .opacity(isEnabling ? 0 : 1)
                    if isEnabling {
                        ProgressView()
                            .tint(JourneyPalette.canvasDeep)
                    }
                }
                .foregroundStyle(JourneyPalette.canvasDeep)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(BBTheme.goldSweep)
                }
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(BBPressStyle())
            .disabled(isEnabling)
            .accessibilityIdentifier("quickSignIn.enable")

            Button("Not Now") {
                Haptics.selection()
                accounts.declineQuickSignInOffer()
                dismiss()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(BBTheme.inkMuted)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .padding(.top, 4)
            .disabled(isEnabling)
            .accessibilityIdentifier("quickSignIn.decline")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(
                colors: [JourneyPalette.canvas, JourneyPalette.canvasDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .animation(.easeOut(duration: 0.2), value: errorMessage)
        .interactiveDismissDisabled(isEnabling)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("quickSignIn.offer")
    }

    private func enable() {
        Haptics.tap()
        errorMessage = nil
        isEnabling = true
        Task {
            defer { isEnabling = false }
            do {
                try await accounts.enableQuickSignIn()
                Haptics.success()
                dismiss()
            } catch BiometricError.cancelled, BiometricError.fallback {
                // User backed out of the system prompt; leave the offer open.
            } catch {
                Haptics.warning()
                errorMessage = (error as? LocalizedError)?.errorDescription
                    ?? "Couldn't turn this on. Please try again."
            }
        }
    }
}
