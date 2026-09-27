//
//  AuthScreen.swift
//  BankrollBoard
//
//  Log in or sign up: logo, email + password + Continue, then Google and Apple.
//  Sections stagger in on first load; a full-screen forgot-password flow is
//  one tap away.
//

import SwiftUI
import UIKit

struct AuthScreen: View {
    /// Prompt Face ID as soon as the screen opens (cold launch only, not after logging out).
    var autoPromptsQuickSignIn: Bool = false
    let onAuthenticated: (AuthSession) -> Void

    @Environment(AccountStore.self) private var accounts
    @State private var model = AuthViewModel()
    @State private var hasAutoPrompted: Bool = false
    @State private var hasAppeared: Bool = false
    @State private var showsForgotPassword: Bool = false
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                BrandLogoView(size: 84)
                    .padding(.top, 44)
                    .scaleEffect(hasAppeared ? 1 : 0.85)
                    .staggeredIn(0, hasAppeared: hasAppeared)

                header
                    .padding(.top, 30)
                    .staggeredIn(1, hasAppeared: hasAppeared)

                if accounts.canQuickSignIn, let account = accounts.quickSignInRecord?.account {
                    VStack(spacing: 18) {
                        QuickSignInButton(
                            account: account,
                            kind: accounts.biometricKind,
                            isLoading: model.isUnlocking,
                            action: quickSignIn
                        )
                        dividerLabel("or use your password")
                    }
                    .padding(.top, 28)
                    .staggeredIn(2, hasAppeared: hasAppeared)
                    .transition(.opacity)
                }

                VStack(spacing: 12) {
                    AuthEmailField(
                        text: $model.email,
                        isFocused: $isEmailFocused,
                        onClear: { model.clearEmail() },
                        onSubmit: { isPasswordFocused = true },
                        submitLabel: .next
                    )
                    AuthPasswordField(
                        text: $model.password,
                        isFocused: $isPasswordFocused,
                        onSubmit: submitCredentials
                    )

                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            Haptics.selection()
                            showsForgotPassword = true
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AuthPalette.forest)
                        .accessibilityIdentifier("auth.forgotLink")
                    }
                    .padding(.top, 2)

                    continueButton
                }
                .padding(.top, accounts.canQuickSignIn ? 18 : 30)
                .staggeredIn(2, hasAppeared: hasAppeared)

                orDivider
                    .padding(.vertical, 20)
                    .staggeredIn(3, hasAppeared: hasAppeared)

                VStack(spacing: 12) {
                    AuthProviderButton(
                        title: "Continue with Google",
                        isLoading: model.pendingProvider == .google,
                        action: { continueWith(.google) }
                    ) {
                        GoogleGlyph()
                            .frame(width: 20, height: 20)
                    }
                    .accessibilityIdentifier("auth.google")

                    AuthProviderButton(
                        title: "Continue with Apple",
                        isLoading: model.pendingProvider == .apple,
                        action: { continueWith(.apple) }
                    ) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20, weight: .medium))
                            .offset(y: -1)
                    }
                    .accessibilityIdentifier("auth.apple")
                }
                .staggeredIn(4, hasAppeared: hasAppeared)

                if let message = model.errorMessage {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AuthPalette.error)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .transition(.opacity)
                }

                footer
                    .padding(.top, 36)
                    .padding(.bottom, 24)
                    .staggeredIn(5, hasAppeared: hasAppeared)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .animation(.easeOut(duration: 0.2), value: model.errorMessage)
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissesKeyboardOnTap()
        .scrollBounceBehavior(.basedOnSize)
        .allowsHitTesting(!model.isBusy)
        .background { AuthBackground() }
        .preferredColorScheme(.light)
        .accessibilityIdentifier("auth.page")
        .fullScreenCover(isPresented: $showsForgotPassword) {
            ForgotPasswordScreen()
        }
        .onAppear {
            accounts.refreshBiometrics()
            if model.email.isEmpty, let email = accounts.quickSignInRecord?.account.email {
                model.email = email
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                hasAppeared = true
            }
            guard autoPromptsQuickSignIn, !hasAutoPrompted, accounts.canQuickSignIn else { return }
            hasAutoPrompted = true
            Task {
                // Let the entrance animation settle before the system prompt covers it.
                try? await Task.sleep(for: .milliseconds(500))
                quickSignIn()
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Text("Log in or sign up")
                .font(BBTheme.headline(32))
                .foregroundStyle(AuthPalette.ink)
            Text("Every deposit and payout, in one calm place.")
                .font(.system(size: 15))
                .foregroundStyle(AuthPalette.inkMuted)
        }
        .multilineTextAlignment(.center)
    }

    private var canSubmit: Bool {
        model.isEmailValid && model.isPasswordValid
    }

    private var continueButton: some View {
        let isLoading = model.pendingProvider == .email
        return Button(action: submitCredentials) {
            ZStack {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(AuthPalette.paper)
                }
            }
            .foregroundStyle(AuthPalette.paper)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AuthPalette.forestLight, AuthPalette.forest],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: AuthPalette.forest.opacity(canSubmit ? 0.22 : 0), radius: 12, y: 6)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(BBPressStyle())
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.4)
        .animation(.easeOut(duration: 0.2), value: canSubmit)
        .accessibilityIdentifier("auth.continue")
    }

    private var orDivider: some View {
        dividerLabel("or")
    }

    private func dividerLabel(_ text: String) -> some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(AuthPalette.hairline)
                .frame(height: 1)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(AuthPalette.inkMuted)
                .fixedSize()
            Rectangle()
                .fill(AuthPalette.hairline)
                .frame(height: 1)
        }
    }

    private var footer: some View {
        Text("By continuing, you agree to Bankroll Board's **Terms** and **Privacy Policy**. For adults 21+ only.")
            .font(.system(size: 12))
            .foregroundStyle(AuthPalette.inkMuted)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
    }

    // MARK: - Actions

    private func submitCredentials() {
        guard canSubmit else { return }
        Haptics.tap()
        isEmailFocused = false
        isPasswordFocused = false
        Task {
            if let session = await model.submitCredentials() {
                finish(session)
            } else {
                Haptics.warning()
            }
        }
    }

    private func continueWith(_ provider: AuthProvider) {
        Haptics.tap()
        isEmailFocused = false
        isPasswordFocused = false
        Task {
            if let session = await model.continueWith(provider) {
                finish(session)
            } else {
                Haptics.warning()
            }
        }
    }

    private func quickSignIn() {
        Haptics.tap()
        isEmailFocused = false
        isPasswordFocused = false
        Task {
            switch await model.quickSignIn(with: accounts) {
            case .signedIn(let session):
                finish(session)
            case .usePassword:
                isPasswordFocused = true
            case .stopped:
                if model.errorMessage != nil { Haptics.warning() }
            }
        }
    }

    private func finish(_ session: AuthSession) {
        Haptics.success()
        onAuthenticated(session)
    }
}

/// Shared paper-toned backdrop for the auth screens.
struct AuthBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AuthPalette.paperLight, AuthPalette.paper, AuthPalette.paperDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.white.opacity(0.8), Color.white.opacity(0)],
                center: UnitPoint(x: 0.5, y: 0.08),
                startRadius: 0,
                endRadius: 340
            )
            RadialGradient(
                colors: [AuthPalette.gold.opacity(0.09), AuthPalette.gold.opacity(0)],
                center: UnitPoint(x: 0.95, y: 1.0),
                startRadius: 0,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

private extension View {
    /// Fades + slides content in, delayed by its position in the load sequence.
    func staggeredIn(_ index: Int, hasAppeared: Bool) -> some View {
        opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 18)
            .animation(
                .spring(response: 0.55, dampingFraction: 0.85)
                    .delay(Double(index) * 0.075),
                value: hasAppeared
            )
    }
}

/// Tapping anywhere on the view resigns the first responder, so the keyboard
/// dismisses without hunting for the exact right spot.
extension View {
    func dismissesKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}

#Preview {
    AuthScreen { _ in }
        .environment(AccountStore())
}
