//
//  AuthEmailField.swift
//  BankrollBoard
//

import SwiftUI

/// Rounded email input with a clear button and a forest focus ring.
struct AuthEmailField: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    let onClear: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            TextField(
                "",
                text: $text,
                prompt: Text("Email address").foregroundStyle(AuthPalette.inkMuted.opacity(0.8))
            )
            .font(.system(size: 17))
            .foregroundStyle(AuthPalette.ink)
            .tint(AuthPalette.forest)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.continue)
            .focused(isFocused)
            .onSubmit(onSubmit)
            .accessibilityIdentifier("auth.email")

            if !text.isEmpty {
                Button {
                    Haptics.selection()
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(AuthPalette.inkMuted.opacity(0.55))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear email")
                .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }
        }
        .padding(.leading, 18)
        .padding(.trailing, text.isEmpty ? 18 : 4)
        .frame(height: 56)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AuthPalette.field)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isFocused.wrappedValue ? AuthPalette.forest.opacity(0.55) : AuthPalette.hairline,
                    lineWidth: isFocused.wrappedValue ? 1.4 : 1
                )
        }
        .animation(.easeOut(duration: 0.18), value: text.isEmpty)
        .animation(.easeOut(duration: 0.18), value: isFocused.wrappedValue)
    }
}
