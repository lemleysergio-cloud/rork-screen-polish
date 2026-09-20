//
//  HomeReauthSheet.swift
//  BankrollBoard
//
//  Placeholder host for Plaid Link in update mode.
//
//  ── Wiring this to Plaid Link ────────────────────────────────────────────
//  The view model has already minted a link token (update mode) for the broken
//  item and handed it over in `request.linkToken`. Replace the body below with
//  the Plaid Link presentation:
//
//      LinkController(configuration: LinkTokenConfiguration(
//          token: request.linkToken,
//          onSuccess: { _ in onFinished() }
//      ))
//
//  On success call `onFinished()` — the view model re-syncs and the stale
//  banner clears itself.
//

import SwiftUI

struct HomeReauthSheet: View {
    let request: HomeViewModel.ReauthRequest
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [JourneyPalette.canvasDeep, JourneyPalette.canvas],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                Image(systemName: "building.columns")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(BBTheme.gold)
                    .frame(width: 84, height: 84)
                    .background {
                        Circle().stroke(BBTheme.gold.opacity(0.3), lineWidth: 1)
                    }

                Text("Reconnect \(request.institutionName)")
                    .font(BBTheme.headline(26))
                    .foregroundStyle(BBTheme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)

                Text("Your bank asks you to sign in again every so often. Once you do, pending and settled transfers resume updating automatically.")
                    .font(.system(size: 13))
                    .foregroundStyle(BBTheme.inkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .padding(.horizontal, 12)

                BBDisclaimerBadge(text: "Secure bank sign-in opens here")
                    .padding(.top, 24)

                Spacer(minLength: 0)

                BBPrimaryButton(title: "Continue", isEnabled: true) {
                    onFinished()
                    dismiss()
                }
                .padding(.top, 20)

                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Text("Not now")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(BBTheme.inkMuted)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BBPressStyle())
                .padding(.top, 4)
            }
            .padding(.horizontal, BBTheme.screenMargin)
            .padding(.vertical, 28)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("home.reauth")
    }
}
