//
//  AuthScreen.swift
//  BankrollBoard
//
//  Log in or sign up: logo, email + Continue, then Google and Apple.
//

import SwiftUI

struct AuthScreen: View {
    let onAuthenticated: (AuthSession) -> Void

    @State private var model = AuthViewModel()
    @State private var hasAppeared: Bool = false
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                BrandLogoView(size: 76)
                    .padding(.top, 52)
                    .scaleEffect(hasAppeared ? 1 : 0.85)
                    .opacity(hasAppeared ? 1 : 0)

                header
                    .padding(.top, 30)
                    .offset(y: hasAppeared ? 0 : 10)
                    .opacity(hasAppeared ? 1 : 0)

                VStack(spacing: 12) {
                    AuthEmailField(
                        text: $model.email,
                        isFocused: $isEmailFocused,
                        onClear: { model.clearEmail() },
                        onSubmit: submitEmail
                    )
                    continueButton
                }
                .padding(.top, 30)

                orDivider
                    .padding(.vertical, 20)

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
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .animation(.easeOut(duration: 0.2), value: model.errorMessage)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .allowsHitTesting(!model.isBusy)
        .background { background }
        .preferredColorScheme(.light)
        .accessibilityIdentifier("auth.page")
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                hasAppeared = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(550))
                isEmailFocused = true
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

    private var continueButton: some View {
        let isLoading = model.pendingProvider == .email
        return Button(action: submitEmail) {
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
                    .shadow(color: AuthPalette.forest.opacity(model.isEmailValid ? 0.22 : 0), radius: 12, y: 6)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(BBPressStyle())
        .disabled(!model.isEmailValid)
        .opacity(model.isEmailValid ? 1 : 0.4)
        .animation(.easeOut(duration: 0.2), value: model.isEmailValid)
        .accessibilityIdentifier("auth.continue")
    }

    private var orDivider: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(AuthPalette.hairline)
                .frame(height: 1)
            Text("or")
                .font(.system(size: 15))
                .foregroundStyle(AuthPalette.inkMuted)
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

    private var background: some View {
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

    // MARK: - Actions

    private func submitEmail() {
        guard model.isEmailValid else { return }
        Haptics.tap()
        isEmailFocused = false
        Task {
            if let session = await model.submitEmail() {
                finish(session)
            } else {
                Haptics.warning()
            }
        }
    }

    private func continueWith(_ provider: AuthProvider) {
        Haptics.tap()
        isEmailFocused = false
        Task {
            if let session = await model.continueWith(provider) {
                finish(session)
            } else {
                Haptics.warning()
            }
        }
    }

    private func finish(_ session: AuthSession) {
        Haptics.success()
        onAuthenticated(session)
    }
}

#Preview {
    AuthScreen { _ in }
}
