//
//  AuthEmailField.swift
//  BankrollBoard
//

import SwiftUI
import UIKit

/// Rounded email input with a clear button and a forest focus ring.
/// Optional inline label and validity checkmark for the forgot-password flow.
struct AuthEmailField: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    let onClear: () -> Void
    let onSubmit: () -> Void
    var label: String? = nil
    var placeholder: String = "Email address"
    var keyboardType: UIKeyboardType = .emailAddress
    var contentType: UITextContentType? = .emailAddress
    /// When non-nil and `true`, shows a green check instead of the clear button.
    var isValid: Bool? = nil
    var submitLabel: SubmitLabel = .continue

    private var showsTrailingControl: Bool { isValid == true || !text.isEmpty }

    var body: some View {
        HStack(spacing: 4) {
            field
            .font(.system(size: 17))
            .foregroundStyle(AuthPalette.ink)
            .tint(AuthPalette.forest)
            .keyboardType(keyboardType)
            .textContentType(contentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(submitLabel)
            .focused(isFocused)
            .onSubmit(onSubmit)
            .accessibilityIdentifier("auth.email")

            if isValid == true {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AuthPalette.success)
                    .frame(width: 44, height: 44)
                    .transition(.opacity.combined(with: .scale(scale: 0.7)))
            } else if !text.isEmpty {
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
        .padding(.trailing, showsTrailingControl ? 4 : 18)
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
        .animation(.easeOut(duration: 0.18), value: isValid == true)
        .animation(.easeOut(duration: 0.18), value: isFocused.wrappedValue)
    }

    @ViewBuilder
    private var field: some View {
        if let label {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AuthPalette.inkMuted)
                TextField("", text: $text)
            }
        } else {
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(AuthPalette.inkMuted.opacity(0.8))
            )
        }
    }
}
