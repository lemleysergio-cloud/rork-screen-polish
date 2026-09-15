//
//  OnboardingCompleteView.swift
//  BankrollBoard
//

import SwiftUI

/// Closing screen after the practice rounds — confirms what was learned and hands off to the board.
struct OnboardingCompleteView: View {
    let highlights: [String]
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    BBHeadlineBlock(
                        eyebrow: "You're set up",
                        title: "Your sample board is ready.",
                        prompt: "We tuned the guidance to your answers. You can change any of it later in settings."
                    )

                    VStack(spacing: BBTheme.cardSpacing) {
                        ForEach(Array(highlights.enumerated()), id: \.offset) { _, line in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(BBTheme.gold)
                                Text(line)
                                    .font(.system(size: 16))
                                    .foregroundStyle(BBTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                                    .fill(BBTheme.surface)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: BBTheme.cardRadius)
                                            .stroke(BBTheme.hairline.opacity(0.55), lineWidth: 1)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, BBTheme.screenMargin)

                    BBFootnote(
                        text: "Bankroll Board is an educational and tracking tool. Operator eligibility and current terms still need to be checked."
                    )
                    .padding(.horizontal, BBTheme.screenMargin)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(BBTheme.hairline.opacity(0.5))
                    .frame(height: 1)

                VStack(spacing: 10) {
                    BBPrimaryButton(title: "Open my board", isEnabled: true) {}

                    Button(action: onRestart) {
                        Text("Run the quiz again")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(BBTheme.gold)
                            .underline()
                            .frame(height: 36)
                    }
                    .buttonStyle(BBPressStyle())
                }
                .padding(.horizontal, BBTheme.screenMargin)
                .padding(.top, 14)
            }
            .background(BBTheme.canvasDeep.opacity(0.92))
        }
    }
}

#Preview {
    OnboardingCompleteView(
        highlights: [
            "Explanations tuned for someone new to welcome offers.",
            "Journey and money tracking enabled for Michigan.",
            "Deposit and playthrough details shown first."
        ],
        onRestart: {}
    )
    .bbCanvasBackground()
}
