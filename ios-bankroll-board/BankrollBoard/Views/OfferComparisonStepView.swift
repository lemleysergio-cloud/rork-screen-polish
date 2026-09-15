//
//  OfferComparisonStepView.swift
//  BankrollBoard
//

import SwiftUI

/// Practice round 1 of 2 — compare two sample offers by total wagering.
struct OfferComparisonStepView: View {
    let offerA: SampleOffer
    let offerB: SampleOffer
    let guess: String?
    let correctID: String
    let showsExplanation: Bool
    let onChoose: (String) -> Void
    let onReveal: () -> Void
    let onContinue: () -> Void

    private func state(for offer: SampleOffer) -> BBChoiceButton.State {
        guard guess != nil else { return .idle }
        if offer.id == correctID { return .correct }
        if offer.id == guess { return .incorrect }
        return .dimmed
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    BBHeadlineBlock(
                        eyebrow: "Practice round · 1 of 2",
                        title: "Look beyond the bonus.",
                        prompt: "A bonus headline is only part of the picture. Compare what each offer actually requires."
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        BBDisclaimerBadge(text: "Illustrative example · not a real offer or forecast")

                        HStack(alignment: .top, spacing: 12) {
                            OfferCard(offer: offerA, isHighlighted: showsExplanation && offerA.id == correctID)
                            OfferCard(offer: offerB, isHighlighted: showsExplanation && offerB.id == correctID)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Which requires less total wagering?")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(BBTheme.ink)

                            HStack(spacing: 12) {
                                BBChoiceButton(title: "Offer A", state: state(for: offerA)) {
                                    onChoose(offerA.id)
                                }
                                BBChoiceButton(title: "Offer B", state: state(for: offerB)) {
                                    onChoose(offerB.id)
                                }
                            }

                            if guess == nil {
                                Button(action: onReveal) {
                                    Text("Show me the comparison")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(BBTheme.gold)
                                        .underline()
                                }
                                .buttonStyle(BBPressStyle())
                            }
                        }

                        if showsExplanation {
                            explanation
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, BBTheme.screenMargin)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .animation(.spring(response: 0.42, dampingFraction: 0.85), value: showsExplanation)

            footer
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let guess, guess != correctID {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 13, weight: .medium))
                    Text("The bigger bonus isn't automatically the easier one.")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(BBTheme.gold)
            }

            VStack(spacing: 10) {
                WageringRow(offer: offerA, isWinner: offerA.id == correctID)
                Rectangle()
                    .fill(BBTheme.hairline.opacity(0.5))
                    .frame(height: 1)
                WageringRow(offer: offerB, isWinner: offerB.id == correctID)
            }

            Text("Total wagering is the bonus multiplied by its playthrough. Offer A asks for $250 of play; Offer B asks for $3,000.")
                .font(BBTheme.caption)
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                .fill(BBTheme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                        .stroke(BBTheme.hairline.opacity(0.6), lineWidth: 1)
                }
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(BBTheme.hairline.opacity(0.5))
                .frame(height: 1)

            BBPrimaryButton(
                title: "Next practice round",
                isEnabled: showsExplanation,
                action: onContinue
            )
            .padding(.horizontal, BBTheme.screenMargin)
            .padding(.top, 14)
            .padding(.bottom, 6)
        }
        .background(BBTheme.canvasDeep.opacity(0.92))
    }
}

/// One sample offer summarized with labeled rows.
private struct OfferCard: View {
    let offer: SampleOffer
    let isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(offer.label)
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .kerning(1.1)
                .foregroundStyle(BBTheme.gold)

            Text("$\(offer.bonus)")
                .font(BBTheme.headline(38))
                .foregroundStyle(BBTheme.ink)
                .padding(.top, 8)

            Text("conditional bonus")
                .font(.system(size: 13))
                .foregroundStyle(BBTheme.inkMuted)
                .padding(.top, 1)

            divider

            MetricRow(label: "Personal deposit", value: "$\(offer.deposit)")

            divider

            MetricRow(label: "Bonus playthrough", value: "\(offer.playthrough)×")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                .fill(isHighlighted ? BBTheme.surfaceRaised : BBTheme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                        .fill(isHighlighted ? BBTheme.goldSoft : Color.clear)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                        .stroke(
                            isHighlighted ? BBTheme.gold : BBTheme.hairline.opacity(0.55),
                            lineWidth: isHighlighted ? 1.6 : 1
                        )
                }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isHighlighted)
    }

    private var divider: some View {
        Rectangle()
            .fill(BBTheme.hairline.opacity(0.5))
            .frame(height: 1)
            .padding(.vertical, 12)
    }
}

private struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(BBTheme.inkMuted)
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BBTheme.ink)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WageringRow: View {
    let offer: SampleOffer
    let isWinner: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(offer.label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BBTheme.ink)

            Spacer()

            Text("$\(offer.bonus) × \(offer.playthrough)")
                .font(.system(size: 13))
                .monospacedDigit()
                .foregroundStyle(BBTheme.inkMuted)

            Text("$\(offer.totalWagering.formatted())")
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(isWinner ? BBTheme.gold : BBTheme.ink)
        }
    }
}

#Preview {
    OfferComparisonStepView(
        offerA: OnboardingContent.offerA,
        offerB: OnboardingContent.offerB,
        guess: "b",
        correctID: "a",
        showsExplanation: true,
        onChoose: { _ in },
        onReveal: {},
        onContinue: {}
    )
    .bbCanvasBackground()
}
