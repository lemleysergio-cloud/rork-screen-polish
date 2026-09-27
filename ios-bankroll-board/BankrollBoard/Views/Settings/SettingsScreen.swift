//
//  SettingsScreen.swift
//  BankrollBoard
//
//  Account info and a Log Out action for the demo build. Logging out flips
//  the shared sign-in flag so the login screen appears again.
//

import SwiftUI

struct SettingsScreen: View {
    let onLogout: () -> Void

    @State private var showsLogoutConfirmation: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [JourneyPalette.canvasDeep, JourneyPalette.canvas, Color(rgb: 0x132F20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ACCOUNT")
                            .font(.system(size: 11, weight: .black))
                            .kerning(1.4)
                            .foregroundStyle(JourneyPalette.gold)
                        Text("Settings")
                            .font(.system(size: 40, weight: .regular, design: .serif))
                            .foregroundStyle(JourneyPalette.ink)
                    }
                    .padding(.top, 24)

                    accountCard
                        .padding(.top, 24)

                    logoutButton
                        .padding(.top, 16)

                    Text("Bankroll Board is a demo build — your data stays on this device.")
                        .font(.system(size: 12))
                        .foregroundStyle(BBTheme.inkMuted)
                        .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, BBTheme.screenMargin)
                .padding(.bottom, 140)
            }
        }
        .confirmationDialog(
            "Log out of Bankroll Board?",
            isPresented: $showsLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                Haptics.tap()
                onLogout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to see your board.")
        }
        .accessibilityIdentifier("settings.page")
    }

    // MARK: - Sections

    private var accountCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(JourneyPalette.gold)
                .frame(width: 52, height: 52)
                .background { Circle().fill(JourneyPalette.gold.opacity(0.12)) }

            VStack(alignment: .leading, spacing: 3) {
                Text("Demo account")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JourneyPalette.ink)
                Text("Everything stays on this device")
                    .font(.system(size: 13))
                    .foregroundStyle(BBTheme.inkMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
    }

    private var logoutButton: some View {
        Button {
            Haptics.selection()
            showsLogoutConfirmation = true
        } label: {
            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(rgb: 0xE58B7E))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(rgb: 0xC96A5C).opacity(0.08))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(rgb: 0xC96A5C).opacity(0.4), lineWidth: 1)
                        }
                }
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(BBPressStyle())
        .accessibilityIdentifier("settings.logout")
    }
}

#Preview {
    SettingsScreen(onLogout: {})
}
