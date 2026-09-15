//
//  QuestionStepView.swift
//  BankrollBoard
//

import SwiftUI

/// A single preference question: headline, compact option cards, sticky CTA.
struct QuestionStepView: View {
    let question: OnboardingQuestion
    let selection: Set<String>
    let onToggle: (String) -> Void
    let onContinue: () -> Void

    private var canContinue: Bool { !selection.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    BBHeadlineBlock(
                        eyebrow: question.eyebrow,
                        title: question.title,
                        prompt: question.prompt
                    )

                    VStack(spacing: BBTheme.cardSpacing) {
                        ForEach(question.options) { option in
                            BBOptionCard(
                                option: option,
                                isSelected: selection.contains(option.id),
                                allowsMultiple: question.allowsMultiple
                            ) {
                                onToggle(option.id)
                            }
                        }
                    }
                    .padding(.horizontal, BBTheme.screenMargin)

                    if let footnote = question.footnote {
                        BBFootnote(text: footnote)
                            .padding(.horizontal, BBTheme.screenMargin)
                            .opacity(canContinue && question.allowsMultiple ? 0 : 1)
                            .animation(.easeOut(duration: 0.2), value: canContinue)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            stickyFooter
        }
    }

    private var stickyFooter: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(BBTheme.hairline.opacity(0.5))
                .frame(height: 1)

            BBPrimaryButton(
                title: question.primaryActionTitle,
                isEnabled: canContinue,
                action: onContinue
            )
            .padding(.horizontal, BBTheme.screenMargin)
            .padding(.top, 14)
            .padding(.bottom, 6)
        }
        .background(BBTheme.canvasDeep.opacity(0.92))
    }
}

#Preview {
    QuestionStepView(
        question: OnboardingContent.questions[2],
        selection: ["playthrough"],
        onToggle: { _ in },
        onContinue: {}
    )
    .bbCanvasBackground()
}
