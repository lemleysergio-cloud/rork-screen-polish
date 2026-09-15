//
//  BBComponents.swift
//  BankrollBoard
//

import SwiftUI

// MARK: - Nav bar

/// Persistent onboarding top bar: back affordance, wordmark, exit link.
struct BBNavBar: View {
    let canGoBack: Bool
    let onBack: () -> Void
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Text("Bankroll Board")
                .font(.system(size: 13, weight: .semibold))
                .textCase(.uppercase)
                .kerning(2.2)
                .foregroundStyle(BBTheme.ink)

            HStack {
                Button(action: {
                    Haptics.tap()
                    onBack()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(canGoBack ? BBTheme.ink : BBTheme.inkMuted.opacity(0.4))
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .stroke(
                                    canGoBack ? BBTheme.hairline : BBTheme.hairline.opacity(0.45),
                                    lineWidth: BBTheme.hairlineWidth
                                )
                        }
                }
                .disabled(!canGoBack)
                .accessibilityLabel("Go back")

                Spacer()

                Button(action: {
                    Haptics.tap()
                    onExit()
                }) {
                    Text("Exit")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(BBTheme.gold)
                        .frame(height: 44)
                        .padding(.horizontal, 4)
                }
                .accessibilityLabel("Exit onboarding")
            }
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }
}

// MARK: - Progress

/// Step progress: numbered pill plus an animated gold track.
struct BBStepProgress: View {
    let step: Int
    let total: Int
    let sectionLabel: String

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(step) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text("\(step)/\(total)")
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(BBTheme.canvasDeep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background {
                        Capsule().fill(BBTheme.gold)
                    }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(BBTheme.hairline.opacity(0.7))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [BBTheme.gold.opacity(0.75), BBTheme.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, proxy.size.width * fraction))
                    }
                }
                .frame(height: 4)
            }

            Text(sectionLabel)
                .font(BBTheme.caption)
                .foregroundStyle(BBTheme.inkMuted)
        }
        .padding(.horizontal, BBTheme.screenMargin)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: fraction)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step) of \(total), \(sectionLabel)")
    }
}

// MARK: - Headline block

/// Eyebrow + serif headline + supporting prompt.
struct BBHeadlineBlock: View {
    let eyebrow: String
    let title: String
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(eyebrow)
                .bbEyebrowStyle()

            Text(title)
                .font(BBTheme.headline(34))
                .foregroundStyle(BBTheme.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(prompt)
                .font(BBTheme.body)
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BBTheme.screenMargin)
    }
}

// MARK: - Option card

/// Compact selectable card: icon, title, subtitle, unambiguous selected state.
struct BBOptionCard: View {
    let option: OnboardingOption
    let isSelected: Bool
    let allowsMultiple: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: option.symbol)
                    .font(.system(size: 19, weight: .light))
                    .foregroundStyle(isSelected ? BBTheme.gold : BBTheme.gold.opacity(0.75))
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(BBTheme.optionTitle)
                        .foregroundStyle(BBTheme.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(BBTheme.optionSubtitle)
                            .foregroundStyle(BBTheme.inkMuted)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                BBSelectionIndicator(isSelected: isSelected, isSquare: allowsMultiple)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                    .fill(isSelected ? BBTheme.surfaceRaised : BBTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                            .fill(isSelected ? BBTheme.goldSoft : Color.clear)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                            .stroke(
                                isSelected ? BBTheme.gold : BBTheme.hairline.opacity(0.55),
                                lineWidth: isSelected ? 1.6 : BBTheme.hairlineWidth
                            )
                    }
            }
        }
        .buttonStyle(BBPressStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Filled checkmark when selected, hairline ring/box when not.
struct BBSelectionIndicator: View {
    let isSelected: Bool
    let isSquare: Bool

    var body: some View {
        ZStack {
            if isSquare {
                RoundedRectangle(cornerRadius: 7)
                    .fill(isSelected ? BBTheme.gold : Color.clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(isSelected ? BBTheme.gold : BBTheme.hairline, lineWidth: 1.4)
                    }
            } else {
                Circle()
                    .fill(isSelected ? BBTheme.gold : Color.clear)
                    .overlay {
                        Circle()
                            .stroke(isSelected ? BBTheme.gold : BBTheme.hairline, lineWidth: 1.4)
                    }
            }

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BBTheme.canvasDeep)
            }
        }
        .frame(width: 26, height: 26)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Buttons

/// Full-width solid gold primary action.
struct BBPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(isEnabled ? BBTheme.canvasDeep : BBTheme.inkMuted)
            .padding(.horizontal, 22)
            .frame(height: 58)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(isEnabled ? BBTheme.gold : BBTheme.surfaceRaised)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isEnabled ? Color.clear : BBTheme.hairline, lineWidth: 1)
                    }
            }
        }
        .buttonStyle(BBPressStyle())
        .disabled(!isEnabled)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }
}

/// Outlined secondary action used for quiz answers and skip links.
struct BBChoiceButton: View {
    let title: String
    let state: State
    let action: () -> Void

    enum State {
        case idle
        case correct
        case incorrect
        case dimmed
    }

    private var fill: Color {
        switch state {
        case .idle, .dimmed: BBTheme.surface
        case .correct: BBTheme.goldSoft
        case .incorrect: Color(red: 0.36, green: 0.16, blue: 0.14).opacity(0.5)
        }
    }

    private var border: Color {
        switch state {
        case .idle: BBTheme.hairline
        case .dimmed: BBTheme.hairline.opacity(0.4)
        case .correct: BBTheme.gold
        case .incorrect: Color(red: 0.85, green: 0.45, blue: 0.40)
        }
    }

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(state == .dimmed ? BBTheme.inkMuted : BBTheme.ink)

                switch state {
                case .correct:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BBTheme.gold)
                case .incorrect:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(red: 0.85, green: 0.45, blue: 0.40))
                case .idle, .dimmed:
                    EmptyView()
                }
            }
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(fill)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(border, lineWidth: state == .idle || state == .dimmed ? 1 : 1.6)
                    }
            }
        }
        .buttonStyle(BBPressStyle())
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state)
    }
}

/// Subtle scale-down press feedback used across all tappable surfaces.
struct BBPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Notices

/// Outlined disclaimer badge for illustrative content.
struct BBDisclaimerBadge: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12, weight: .medium))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .kerning(0.8)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(BBTheme.gold.opacity(0.9))
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .stroke(BBTheme.gold.opacity(0.35), lineWidth: 1)
        }
    }
}

/// Small caption row with a leading icon, used for eligibility notes.
struct BBFootnote: View {
    let text: String
    var symbol: String = "info.circle"

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BBTheme.inkMuted)
                .padding(.top, 1)
            Text(text)
                .font(BBTheme.caption)
                .foregroundStyle(BBTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
