//
//  CommunitySheets.swift
//  BankrollBoard
//
//  Consent, guidelines, and community-creation sheets.
//

import SwiftUI

/// Explicit opt-in before any result is published to a board.
struct CommunityConsentSheet: View {
    let board: CommunityBoard
    let needsGuidelines: Bool
    let onOpenGuidelines: () -> Void
    let onConfirm: () -> Void

    @State private var acceptsSharing = false
    @State private var acceptsGuidelines = false
    @Environment(\.dismiss) private var dismiss

    private var canConfirm: Bool {
        acceptsSharing && (!needsGuidelines || acceptsGuidelines)
    }

    var body: some View {
        ZStack {
            JourneyPalette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("EXPLICIT CONSENT")
                        .font(.system(size: 11, weight: .black))
                        .kerning(1.4)
                        .foregroundStyle(JourneyPalette.gold)

                    Text(board == .publicBoard ? "Join the public board?" : "Share in this group?")
                        .font(BBTheme.headline(30))
                        .foregroundStyle(JourneyPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Turning this on publishes the following to \(board == .publicBoard ? "all Community users" : "members of this group"):")
                        .font(.system(size: 14))
                        .foregroundStyle(BBTheme.inkMuted)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 10) {
                        bullet("Your username and approved profile picture")
                        bullet("Your 7-day, 30-day, 365-day, YTD, and all-time results")
                        bullet("Your all-time Bankroll Board cash-flow balance")
                        bullet("Your verified Journey progress and distinction")
                    }

                    checkRow(
                        isOn: $acceptsSharing,
                        text: "I understand this is optional and can be turned off immediately."
                    )

                    if needsGuidelines {
                        checkRow(
                            isOn: $acceptsGuidelines,
                            text: "I have read and agree to the Community Guidelines."
                        )

                        Button {
                            Haptics.tap()
                            onOpenGuidelines()
                        } label: {
                            Text("Read the Guidelines")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(JourneyPalette.gold)
                        }
                        .buttonStyle(BBPressStyle())
                    }

                    Button {
                        onConfirm()
                    } label: {
                        Text("Enable sharing")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(canConfirm ? JourneyPalette.canvasDeep : BBTheme.inkMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(canConfirm ? JourneyPalette.gold : Color.white.opacity(0.06))
                            }
                    }
                    .buttonStyle(BBPressStyle())
                    .disabled(!canConfirm)
                    .padding(.top, 4)

                    Text("Bankroll Board never publishes your legal name, email, phone, date of birth, bank connections, or raw transactions.")
                        .font(.system(size: 11))
                        .foregroundStyle(BBTheme.inkMuted)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(JourneyPalette.gold.opacity(0.7))
                .frame(width: 5, height: 5)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color(rgb: 0xD6DDD1))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func checkRow(isOn: Binding<Bool>, text: String) -> some View {
        Button {
            Haptics.selection()
            isOn.wrappedValue.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                BBSelectionIndicator(isSelected: isOn.wrappedValue, isSquare: true)
                Text(text)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(rgb: 0xD6DDD1))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(BBPressStyle())
        .accessibilityAddTraits(isOn.wrappedValue ? [.isSelected] : [])
    }
}

/// Plain-language safety rules with an acceptance action.
struct CommunityGuidelinesSheet: View {
    let isAccepted: Bool
    let onAccept: () -> Void

    @State private var checked = false

    var body: some View {
        ZStack {
            JourneyPalette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("COMMUNITY SAFETY")
                        .font(.system(size: 11, weight: .black))
                        .kerning(1.4)
                        .foregroundStyle(JourneyPalette.gold)

                    Text("Community Guidelines")
                        .font(BBTheme.headline(30))
                        .foregroundStyle(JourneyPalette.ink)

                    Text("Community is for accountability and mutual support — not pressure, wagering advice, or proof of skill.")
                        .font(.system(size: 14))
                        .foregroundStyle(BBTheme.inkMuted)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    rule(
                        "Respect people",
                        "No harassment, threats, hate speech, bullying, sexual exploitation, or encouragement of self-harm."
                    )
                    rule(
                        "Protect privacy",
                        "Do not post names, addresses, contact details, financial account information, or anyone's private content."
                    )
                    rule(
                        "Keep it genuine",
                        "No spam, scams, impersonation, illegal content, deceptive claims, or pressure to gamble or chase a loss."
                    )

                    Text("You can report content and block another member from any profile or comment menu. Reports go to the protected moderation queue for prompt review.")
                        .font(.system(size: 12))
                        .foregroundStyle(BBTheme.inkMuted)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if isAccepted {
                        Text("✓ Current Guidelines accepted")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(JourneyPalette.success)
                    } else {
                        Button {
                            Haptics.selection()
                            checked.toggle()
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                BBSelectionIndicator(isSelected: checked, isSquare: true)
                                Text("I have read and agree to follow these Guidelines.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(rgb: 0xD6DDD1))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(BBPressStyle())

                        Button {
                            onAccept()
                        } label: {
                            Text("Accept Guidelines")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(checked ? JourneyPalette.canvasDeep : BBTheme.inkMuted)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(checked ? JourneyPalette.gold : Color.white.opacity(0.06))
                                }
                        }
                        .buttonStyle(BBPressStyle())
                        .disabled(!checked)
                    }
                }
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func rule(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(JourneyPalette.ink)
            Text(body)
                .font(.system(size: 12))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.035))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(BBTheme.hairline.opacity(0.55), lineWidth: 1)
                }
        }
    }
}

/// Names a new private board.
struct CommunityCreateGroupSheet: View {
    @Binding var name: String
    let onCreate: () -> Void

    @FocusState private var fieldFocused: Bool

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            JourneyPalette.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("PRIVATE COMMUNITY")
                    .font(.system(size: 11, weight: .black))
                    .kerning(1.4)
                    .foregroundStyle(JourneyPalette.gold)

                Text("Create a friends board")
                    .font(BBTheme.headline(28))
                    .foregroundStyle(JourneyPalette.ink)

                Text("You can own up to five communities with 50 members each.")
                    .font(.system(size: 13))
                    .foregroundStyle(BBTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                TextField("Friday Night Crew", text: $name)
                    .font(.system(size: 16))
                    .foregroundStyle(JourneyPalette.ink)
                    .tint(JourneyPalette.gold)
                    .focused($fieldFocused)
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(BBTheme.hairline.opacity(0.7), lineWidth: 1)
                            }
                    }

                Button {
                    onCreate()
                } label: {
                    Text("Create and share")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(trimmed.isEmpty ? BBTheme.inkMuted : JourneyPalette.canvasDeep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(trimmed.isEmpty ? Color.white.opacity(0.06) : JourneyPalette.gold)
                        }
                }
                .buttonStyle(BBPressStyle())
                .disabled(trimmed.isEmpty)

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
        .onAppear { fieldFocused = true }
    }
}
