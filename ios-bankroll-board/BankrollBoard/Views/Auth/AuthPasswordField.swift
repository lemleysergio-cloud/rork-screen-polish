//
//  AuthPasswordField.swift
//  BankrollBoard
//
//  Rounded password input with a show/hide toggle and a forest focus ring.
//

import SwiftUI

/// Rounded password input with an eye toggle that reveals the text.
struct AuthPasswordField: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    @State private var isVisible: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Group {
                if isVisible {
                    TextField("", text: $text)
                } else {
                    SecureField("", text: $text)
                }
            }
            .font(.system(size: 17))
            .foregroundStyle(AuthPalette.ink)
            .tint(AuthPalette.forest)
            .textContentType(.password)
            .submitLabel(.continue)
            .focused(isFocused)
            .onSubmit(onSubmit)
            .accessibilityIdentifier("auth.password")

            Button {
                Haptics.selection()
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AuthPalette.inkMuted.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
            .accessibilityIdentifier("auth.passwordToggle")
        }
        .padding(.leading, 18)
        .padding(.trailing, 4)
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
        .animation(.easeOut(duration: 0.18), value: isFocused.wrappedValue)
    }
}

#Preview {
    struct PreviewHost: View {
        @FocusState private var isFocused: Bool

        var body: some View {
            AuthPasswordField(text: .constant(""), isFocused: $isFocused, onSubmit: {})
                .padding()
                .background(AuthPalette.paper)
        }
    }

    return PreviewHost()
}
