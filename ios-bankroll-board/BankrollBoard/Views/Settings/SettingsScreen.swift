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

    @Environment(AccountStore.self) private var accounts
    @State private var showsLogoutConfirmation: Bool = false
    @State private var isTogglingQuickSignIn: Bool = false
    @State private var securityMessage: String?

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

                    Text("SECURITY")
                        .font(.system(size: 11, weight: .black))
                        .kerning(1.4)
                        .foregroundStyle(JourneyPalette.gold)
                        .padding(.top, 28)

                    securityCard
                        .padding(.top, 10)

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
            Text(logoutMessage)
        }
        .onAppear { accounts.refreshBiometrics() }
        .animation(.easeOut(duration: 0.2), value: securityMessage)
        .accessibilityIdentifier("settings.page")
    }

    private var logoutMessage: String {
        accounts.isQuickSignInEnabled
            ? "You can sign back in with \(accounts.biometricKind.title)."
            : "You'll need to sign in again to see your board."
    }

    // MARK: - Security

    private var quickSignInBinding: Binding<Bool> {
        Binding(
            get: { accounts.isQuickSignInEnabled },
            set: { isOn in setQuickSignIn(isOn) }
        )
    }

    private var securityCaption: String {
        if let securityMessage { return securityMessage }
        if accounts.isQuickSignInEnabled {
            return "Open your board with a glance instead of typing your password."
        }
        if !accounts.canUseBiometrics {
            return accounts.biometrics.unavailableReason ?? "Not available on this device."
        }
        return "Skip the password when you sign in."
    }

    private var securityCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: accounts.biometricKind.symbol)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(JourneyPalette.gold)
                .frame(width: 44, height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(JourneyPalette.gold.opacity(0.12))
                }

            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: quickSignInBinding) {
                    Text("Sign in with \(accounts.biometricKind.title)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(JourneyPalette.ink)
                }
                .tint(BBTheme.gold)
                .disabled(isTogglingQuickSignIn || (!accounts.canUseBiometrics && !accounts.isQuickSignInEnabled))
                .accessibilityIdentifier("settings.faceID")

                Text(securityCaption)
                    .font(.system(size: 13))
                    .foregroundStyle(securityMessage == nil ? BBTheme.inkMuted : Color(rgb: 0xE58B7E))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 56)
            }
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

    private func setQuickSignIn(_ isOn: Bool) {
        securityMessage = nil
        guard isOn else {
            Haptics.selection()
            accounts.disableQuickSignIn()
            return
        }
        isTogglingQuickSignIn = true
        Task {
            defer { isTogglingQuickSignIn = false }
            do {
                try await accounts.enableQuickSignIn()
                Haptics.success()
            } catch BiometricError.cancelled, BiometricError.fallback {
                // Backed out of the system prompt; the toggle stays off.
            } catch {
                Haptics.warning()
                securityMessage = (error as? LocalizedError)?.errorDescription
                    ?? "Couldn't turn this on. Please try again."
            }
        }
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
                Text(accounts.currentAccount?.displayName ?? "Demo account")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JourneyPalette.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(accounts.currentAccount?.providerLine ?? "Everything stays on this device")
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
        .environment(AccountStore())
}
