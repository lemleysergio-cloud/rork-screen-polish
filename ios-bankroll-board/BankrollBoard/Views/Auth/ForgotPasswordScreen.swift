//
//  ForgotPasswordScreen.swift
//  BankrollBoard
//
//  Complete reset flow: identify account, verify emailed code, set a new
//  password, and return to login.
//

import SwiftUI

struct ForgotPasswordScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model: AuthViewModel
    @State private var completionAppeared = false
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isCodeFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @FocusState private var isConfirmationFocused: Bool

    init(prefilledEmail: String = "", service: any AuthService = DemoAuthService()) {
        let model = AuthViewModel(service: service)
        model.email = prefilledEmail
        _model = State(initialValue: model)
    }

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(spacing: 0) {
                    topBar

                    Group {
                        switch model.resetStage {
                        case .request: requestForm
                        case .verify: verificationForm
                        case .newPassword: newPasswordForm
                        case .complete: completionState
                        }
                    }
                    .padding(.top, model.resetStage == .complete ? 64 : 34)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.45, dampingFraction: 0.86), value: model.resetStage)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissesKeyboardOnTap()
            .allowsHitTesting(!model.isBusy)
        }
        .preferredColorScheme(.light)
        .accessibilityIdentifier("auth.forgot")
    }

    private var topBar: some View {
        HStack {
            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AuthPalette.ink)
                    .frame(width: 44, height: 44)
                    .background { Circle().fill(Color.white.opacity(0.78)) }
                    .overlay { Circle().stroke(AuthPalette.hairline, lineWidth: 1) }
                    .contentShape(Circle())
            }
            .buttonStyle(BBPressStyle())
            .accessibilityLabel("Back to log in")
            .accessibilityIdentifier("auth.forgot.back")

            Spacer()

            if model.resetStage != .request && model.resetStage != .complete {
                Text(stepLabel)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AuthPalette.inkMuted)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Capsule().fill(Color.white.opacity(0.68)))
                    .overlay(Capsule().stroke(AuthPalette.hairline, lineWidth: 1))
            }
        }
        .padding(.top, 12)
    }

    private var stepLabel: String {
        switch model.resetStage {
        case .verify: "STEP 2 OF 3"
        case .newPassword: "STEP 3 OF 3"
        default: ""
        }
    }

    private var requestForm: some View {
        VStack(spacing: 0) {
            heading(
                title: "Reset your password",
                subtitle: "Enter the email linked to your account. We'll send a six-digit verification code."
            )

            AuthEmailField(
                text: $model.email,
                isFocused: $isEmailFocused,
                onClear: model.clearEmail,
                onSubmit: requestReset,
                placeholder: "Email address",
                isValid: model.isEmailValid
            )
            .padding(.top, 28)

            primaryButton(
                title: "Send Verification Code",
                enabled: model.isEmailValid,
                action: requestReset
            )
            .padding(.top, 16)
            .accessibilityIdentifier("auth.forgot.continue")

            errorMessage
        }
    }

    private var verificationForm: some View {
        VStack(spacing: 0) {
            heading(
                title: "Check your email",
                subtitle: "Enter the six-digit code sent to \(model.trimmedEmail)."
            )

            TextField("000000", text: $model.resetCode)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AuthPalette.ink)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFocused)
                .onChange(of: model.resetCode) { _, value in
                    let digits = value.filter(\.isNumber)
                    if digits != value || digits.count > 6 {
                        model.resetCode = String(digits.prefix(6))
                    }
                }
                .frame(height: 64)
                .background {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(AuthPalette.field)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(
                            isCodeFocused ? AuthPalette.communityBlue : AuthPalette.hairline,
                            lineWidth: isCodeFocused ? 1.5 : 1
                        )
                }
                .padding(.top, 28)
                .accessibilityLabel("Verification code")
                .accessibilityIdentifier("auth.forgot.code")

            primaryButton(
                title: "Verify Code",
                enabled: model.isResetCodeValid,
                action: verifyCode
            )
            .padding(.top, 16)
            .accessibilityIdentifier("auth.forgot.verify")

            Button("Send a new code") {
                Haptics.selection()
                Task {
                    if await model.resendPasswordReset() { Haptics.success() }
                    else { Haptics.warning() }
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AuthPalette.communityBlue)
            .padding(.top, 18)
            .accessibilityIdentifier("auth.forgot.resend")

            errorMessage
        }
        .onAppear { isCodeFocused = true }
    }

    private var newPasswordForm: some View {
        VStack(spacing: 0) {
            heading(
                title: "Choose a new password",
                subtitle: "Use at least eight characters and make it different from passwords you use elsewhere."
            )

            VStack(spacing: 12) {
                AuthPasswordField(
                    text: $model.newPassword,
                    isFocused: $isPasswordFocused,
                    onSubmit: { isConfirmationFocused = true },
                    placeholder: "New password",
                    contentType: .newPassword
                )

                AuthPasswordField(
                    text: $model.confirmedPassword,
                    isFocused: $isConfirmationFocused,
                    onSubmit: setNewPassword,
                    placeholder: "Confirm new password",
                    contentType: .newPassword
                )
            }
            .padding(.top, 28)

            if !model.confirmedPassword.isEmpty && model.newPassword != model.confirmedPassword {
                Label("Passwords don't match yet.", systemImage: "exclamationmark.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AuthPalette.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                    .padding(.horizontal, 4)
            }

            primaryButton(
                title: "Update Password",
                enabled: model.canSetNewPassword,
                action: setNewPassword
            )
            .padding(.top, 16)
            .accessibilityIdentifier("auth.forgot.update")

            errorMessage
        }
    }

    private var completionState: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(AuthPalette.passGo.opacity(0.18))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AuthPalette.success)
            }
            .scaleEffect(completionAppeared ? 1 : 0.55)
            .opacity(completionAppeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.62).delay(0.05)) {
                    completionAppeared = true
                }
            }

            Text("Password updated")
                .font(BBTheme.headline(29))
                .foregroundStyle(AuthPalette.ink)
                .padding(.top, 24)

            Text("Your password is ready. Return to login and sign in with your email or username.")
                .font(.system(size: 15))
                .foregroundStyle(AuthPalette.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            primaryButton(title: "Back to Log In", enabled: true) {
                Haptics.tap()
                dismiss()
            }
            .padding(.top, 30)
            .accessibilityIdentifier("auth.forgot.done")
        }
    }

    private func heading(title: String, subtitle: String) -> some View {
        VStack(spacing: 9) {
            Text(title)
                .font(BBTheme.headline(30))
                .foregroundStyle(AuthPalette.ink)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(AuthPalette.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func primaryButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .opacity(model.isBusy ? 0 : 1)
                if model.isBusy { ProgressView().tint(.white) }
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
                    .shadow(color: AuthPalette.forest.opacity(enabled ? 0.2 : 0), radius: 12, y: 6)
            }
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(BBPressStyle())
        .disabled(!enabled || model.isBusy)
        .opacity(enabled ? 1 : 0.42)
        .animation(.easeOut(duration: 0.2), value: enabled)
    }

    @ViewBuilder
    private var errorMessage: some View {
        if let message = model.errorMessage {
            Label(message, systemImage: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AuthPalette.error)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .accessibilityIdentifier("auth.forgot.error")
        }
    }

    private func requestReset() {
        guard model.isEmailValid, !model.isBusy else { return }
        Haptics.tap()
        isEmailFocused = false
        Task {
            if await model.requestPasswordReset() { Haptics.success() }
            else { Haptics.warning() }
        }
    }

    private func verifyCode() {
        guard model.isResetCodeValid, !model.isBusy else { return }
        Haptics.tap()
        isCodeFocused = false
        Task {
            if await model.verifyPasswordReset() { Haptics.success() }
            else { Haptics.warning() }
        }
    }

    private func setNewPassword() {
        guard model.canSetNewPassword, !model.isBusy else { return }
        Haptics.tap()
        isPasswordFocused = false
        isConfirmationFocused = false
        Task {
            if await model.completePasswordReset() { Haptics.success() }
            else { Haptics.warning() }
        }
    }
}

#Preview {
    ForgotPasswordScreen(prefilledEmail: "hello@bankrollboard.app")
}
