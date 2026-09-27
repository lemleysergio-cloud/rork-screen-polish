//
//  AuthScreen.swift
//  BankrollBoard
//
//  Focused authentication surface: username/email + password, or Google/Apple.
//

import SwiftUI
import UIKit

struct AuthScreen: View {
    var autoPromptsQuickSignIn: Bool = false
    let onAuthenticated: (AuthSession) -> Void
    private let service: any AuthService

    @Environment(AccountStore.self) private var accounts
    @State private var model: AuthViewModel
    @State private var hasAutoPrompted = false
    @State private var hasAppeared = false
    @State private var showsForgotPassword = false
    @FocusState private var isIdentifierFocused: Bool
    @FocusState private var isUsernameFocused: Bool
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    init(
        autoPromptsQuickSignIn: Bool = false,
        service: any AuthService = DemoAuthService(),
        onAuthenticated: @escaping (AuthSession) -> Void
    ) {
        self.autoPromptsQuickSignIn = autoPromptsQuickSignIn
        self.service = service
        self.onAuthenticated = onAuthenticated
        _model = State(initialValue: AuthViewModel(service: service))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                BrandLogoView(size: 72)
                    .padding(.top, 28)
                    .scaleEffect(hasAppeared ? 1 : 0.88)
                    .staggeredIn(0, hasAppeared: hasAppeared)

                header
                    .padding(.top, 18)
                    .staggeredIn(1, hasAppeared: hasAppeared)

                modePicker
                    .padding(.top, 22)
                    .staggeredIn(2, hasAppeared: hasAppeared)

                if model.mode == .login,
                   accounts.canQuickSignIn,
                   let account = accounts.quickSignInRecord?.account {
                    VStack(spacing: 16) {
                        QuickSignInButton(
                            account: account,
                            kind: accounts.biometricKind,
                            isLoading: model.isUnlocking,
                            action: quickSignIn
                        )
                        dividerLabel("or use your password")
                    }
                    .padding(.top, 22)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                credentialForm
                    .padding(.top, 22)
                    .staggeredIn(3, hasAppeared: hasAppeared)

                dividerLabel("or continue with")
                    .padding(.vertical, 18)
                    .staggeredIn(4, hasAppeared: hasAppeared)

                providerButtons
                    .staggeredIn(5, hasAppeared: hasAppeared)

                if let message = model.errorMessage {
                    Label(message, systemImage: "exclamationmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AuthPalette.error)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .transition(.opacity)
                        .accessibilityIdentifier("auth.error")
                }

                footer
                    .padding(.top, 26)
                    .padding(.bottom, 24)
                    .staggeredIn(6, hasAppeared: hasAppeared)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.4, dampingFraction: 0.86), value: model.mode)
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
            ForgotPasswordScreen(prefilledEmail: loginEmailForReset, service: service)
        }
        .onAppear {
            accounts.refreshBiometrics()
            if model.identifier.isEmpty, let saved = accounts.quickSignInRecord?.account.email {
                model.identifier = saved
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                hasAppeared = true
            }
            guard autoPromptsQuickSignIn, !hasAutoPrompted, accounts.canQuickSignIn else { return }
            hasAutoPrompted = true
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                quickSignIn()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 7) {
            Text(model.mode == .login ? "Welcome back" : "Create your account")
                .font(BBTheme.headline(31))
                .foregroundStyle(AuthPalette.ink)
                .contentTransition(.opacity)
            Text(model.mode == .login
                 ? "Your bankroll, offers, and progress are ready."
                 : "Start tracking every deposit and payout in one place.")
                .font(.system(size: 15))
                .foregroundStyle(AuthPalette.inkMuted)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(AuthMode.allCases, id: \.rawValue) { mode in
                Button {
                    Haptics.selection()
                    resignFocus()
                    model.setMode(mode)
                } label: {
                    Text(mode.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(model.mode == mode ? Color.white : AuthPalette.inkMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background {
                            if model.mode == mode {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(AuthPalette.forest)
                                    .matchedGeometryEffect(id: "auth-mode", in: modeAnimation)
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("auth.mode.\(mode.rawValue)")
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.white.opacity(0.64))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(AuthPalette.hairline, lineWidth: 1)
                }
        }
    }

    @Namespace private var modeAnimation

    @ViewBuilder
    private var credentialForm: some View {
        VStack(spacing: 12) {
            if model.mode == .login {
                AuthEmailField(
                    text: $model.identifier,
                    isFocused: $isIdentifierFocused,
                    onClear: model.clearIdentifier,
                    onSubmit: { isPasswordFocused = true },
                    placeholder: "Email or username",
                    keyboardType: .emailAddress,
                    contentType: .username,
                    submitLabel: .next
                )
                .accessibilityIdentifier("auth.identifier")
            } else {
                AuthEmailField(
                    text: $model.username,
                    isFocused: $isUsernameFocused,
                    onClear: model.clearUsername,
                    onSubmit: { isEmailFocused = true },
                    placeholder: "Username",
                    keyboardType: .asciiCapable,
                    contentType: .username,
                    submitLabel: .next
                )
                .accessibilityIdentifier("auth.username")

                AuthEmailField(
                    text: $model.email,
                    isFocused: $isEmailFocused,
                    onClear: model.clearEmail,
                    onSubmit: { isPasswordFocused = true },
                    placeholder: "Email address",
                    submitLabel: .next
                )
            }

            AuthPasswordField(
                text: $model.password,
                isFocused: $isPasswordFocused,
                onSubmit: submitCredentials,
                placeholder: model.mode == .login ? "Password" : "Create a password",
                contentType: model.mode == .login ? .password : .newPassword
            )

            if model.mode == .signUp {
                Text("Use at least 8 characters.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AuthPalette.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            } else {
                HStack {
                    Spacer()
                    Button("Forgot password?") {
                        Haptics.selection()
                        showsForgotPassword = true
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AuthPalette.communityBlue)
                    .accessibilityIdentifier("auth.forgotLink")
                }
                .padding(.top, 1)
            }

            primaryButton
                .padding(.top, 2)
        }
    }

    private var primaryButton: some View {
        let loading = model.pendingProvider == .email
        return Button(action: submitCredentials) {
            ZStack {
                Text(model.mode == .login ? "Log In" : "Create Account")
                    .font(.system(size: 17, weight: .bold))
                    .opacity(loading ? 0 : 1)
                if loading { ProgressView().tint(.white) }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AuthPalette.forestLight, AuthPalette.forest],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AuthPalette.forest.opacity(model.canSubmitCredentials ? 0.2 : 0), radius: 12, y: 6)
            }
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(BBPressStyle())
        .disabled(!model.canSubmitCredentials)
        .opacity(model.canSubmitCredentials ? 1 : 0.42)
        .animation(.easeOut(duration: 0.2), value: model.canSubmitCredentials)
        .accessibilityIdentifier("auth.continue")
    }

    private var providerButtons: some View {
        VStack(spacing: 12) {
            AuthProviderButton(
                title: "Continue with Google",
                isLoading: model.pendingProvider == .google,
                action: { continueWith(.google) }
            ) {
                GoogleGlyph().frame(width: 20, height: 20)
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
    }

    private func dividerLabel(_ text: String) -> some View {
        HStack(spacing: 14) {
            Rectangle().fill(AuthPalette.hairline).frame(height: 1)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AuthPalette.inkMuted)
                .fixedSize()
            Rectangle().fill(AuthPalette.hairline).frame(height: 1)
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

    private var loginEmailForReset: String {
        model.trimmedIdentifier.contains("@") ? model.trimmedIdentifier : ""
    }

    private func submitCredentials() {
        guard model.canSubmitCredentials else { return }
        Haptics.tap()
        resignFocus()
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
        resignFocus()
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
        resignFocus()
        Task {
            switch await model.quickSignIn(with: accounts) {
            case .signedIn(let session): finish(session)
            case .usePassword: isPasswordFocused = true
            case .stopped:
                if model.errorMessage != nil { Haptics.warning() }
            }
        }
    }

    private func resignFocus() {
        isIdentifierFocused = false
        isUsernameFocused = false
        isEmailFocused = false
        isPasswordFocused = false
    }

    private func finish(_ session: AuthSession) {
        Haptics.success()
        onAuthenticated(session)
    }
}

struct AuthBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AuthPalette.paperLight, AuthPalette.boardGreen.opacity(0.78), AuthPalette.paper],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.white.opacity(0.9), Color.white.opacity(0)],
                center: UnitPoint(x: 0.18, y: 0.06),
                startRadius: 0,
                endRadius: 360
            )
            RadialGradient(
                colors: [AuthPalette.communityBlue.opacity(0.09), Color.clear],
                center: UnitPoint(x: 0.92, y: 0.92),
                startRadius: 0,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func staggeredIn(_ index: Int, hasAppeared: Bool) -> some View {
        opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 16)
            .animation(
                .spring(response: 0.52, dampingFraction: 0.86)
                    .delay(Double(index) * 0.06),
                value: hasAppeared
            )
    }
}

extension View {
    func dismissesKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}

#Preview {
    AuthScreen { _ in }
        .environment(AccountStore())
}
