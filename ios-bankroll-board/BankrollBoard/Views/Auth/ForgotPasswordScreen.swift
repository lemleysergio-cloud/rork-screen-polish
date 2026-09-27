//
//  ForgotPasswordScreen.swift
//  BankrollBoard
//
//  Email + Continue sends a (demo) reset link, then shows an inbox
//  confirmation with a way back to the login screen.
//

import SwiftUI

struct ForgotPasswordScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model = AuthViewModel()
    @State private var hasSent: Bool = false
    @State private var checkAppeared: Bool = false
    @State private var sentEmail: String = ""
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(spacing: 0) {
                    topBar

                    if hasSent {
                        sentState
                            .padding(.top, 72)
                            .transition(.opacity)
                    } else {
                        form
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: hasSent)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissesKeyboardOnTap()
            .allowsHitTesting(!model.isBusy)
        }
        .preferredColorScheme(.light)
        .accessibilityIdentifier("auth.forgot")
    }

    // MARK: - Sections

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
                    .background { Circle().fill(AuthPalette.field) }
                    .overlay { Circle().stroke(AuthPalette.hairline, lineWidth: 1) }
                    .contentShape(Circle())
            }
            .buttonStyle(BBPressStyle())
            .accessibilityLabel("Back to log in")
            .accessibilityIdentifier("auth.forgot.back")

            Spacer()
        }
        .padding(.top, 12)
    }

    private var form: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Forgot Password")
                    .font(BBTheme.headline(32))
                    .foregroundStyle(AuthPalette.ink)
                Text("Enter the email linked to your account and we'll send you a link to reset your password.")
                    .font(.system(size: 15))
                    .foregroundStyle(AuthPalette.inkMuted)
                    .multilineTextAlignment(.center)
            }

            AuthEmailField(
                text: $model.email,
                isFocused: $isEmailFocused,
                onClear: { model.clearEmail() },
                onSubmit: sendReset,
                label: "Email",
                isValid: model.isEmailValid
            )
            .padding(.top, 28)

            continueButton
                .padding(.top, 16)

            if let message = model.errorMessage {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AuthPalette.error)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.errorMessage)
    }

    private var continueButton: some View {
        let isLoading = model.isBusy
        return Button(action: sendReset) {
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
        .accessibilityIdentifier("auth.forgot.continue")
    }

    private var sentState: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(AuthPalette.success.opacity(0.14))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AuthPalette.success)
            }
            .scaleEffect(checkAppeared ? 1 : 0.5)
            .opacity(checkAppeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.05)) {
                    checkAppeared = true
                }
            }

            Text("Check your inbox")
                .font(BBTheme.headline(28))
                .foregroundStyle(AuthPalette.ink)
                .padding(.top, 24)

            Text("We sent a password reset link to **\(sentEmail)**.")
                .font(.system(size: 15))
                .foregroundStyle(AuthPalette.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Text("Back to Log In")
                    .font(.system(size: 17, weight: .semibold))
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
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(BBPressStyle())
            .padding(.top, 32)
            .accessibilityIdentifier("auth.forgot.done")
        }
    }

    // MARK: - Actions

    private func sendReset() {
        guard model.isEmailValid, !model.isBusy else { return }
        Haptics.tap()
        isEmailFocused = false
        Task {
            if await model.sendPasswordReset() {
                sentEmail = model.trimmedEmail
                Haptics.success()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    hasSent = true
                }
            } else {
                Haptics.warning()
            }
        }
    }
}

#Preview {
    ForgotPasswordScreen()
}
