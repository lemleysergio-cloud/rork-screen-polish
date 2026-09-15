//
//  OnboardingFlowView.swift
//  BankrollBoard
//

import SwiftUI

/// Container for the 7-step onboarding quiz: persistent nav bar, progress, and step content.
struct OnboardingFlowView: View {
    @State private var model = OnboardingViewModel()
    @State private var showExitConfirmation: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            BBNavBar(
                canGoBack: model.canGoBack,
                onBack: { withAnimation(.easeInOut(duration: 0.22)) { model.goBack() } },
                onExit: { showExitConfirmation = true }
            )
            .padding(.top, 4)

            BBStepProgress(
                step: model.currentStep,
                total: model.totalSteps,
                sectionLabel: model.sectionLabel
            )
            .padding(.top, 18)

            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .bbCanvasBackground()
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Leave setup?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Leave setup", role: .destructive) { model.restart() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Your answers so far won't be saved.")
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch model.stage {
        case .question(let index):
            if let question = model.currentQuestion {
                QuestionStepView(
                    question: question,
                    selection: model.selection(for: question.id),
                    onToggle: { optionID in
                        model.toggle(
                            questionID: question.id,
                            optionID: optionID,
                            allowsMultiple: question.allowsMultiple
                        )
                    },
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.22)) { model.advance() }
                    }
                )
                .id(index)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }

        case .offerComparison:
            OfferComparisonStepView(
                offerA: OnboardingContent.offerA,
                offerB: OnboardingContent.offerB,
                guess: model.offerGuess,
                correctID: model.correctOfferID,
                showsExplanation: model.showsOfferExplanation,
                onChoose: { id in
                    model.chooseOffer(id)
                    if id == model.correctOfferID {
                        Haptics.success()
                    } else {
                        Haptics.warning()
                    }
                },
                onReveal: { model.revealOfferComparison() },
                onContinue: {
                    withAnimation(.easeInOut(duration: 0.22)) { model.advance() }
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity
            ))

        case .houseEdge:
            HouseEdgeStepView(
                items: OnboardingContent.houseEdgeItems,
                selectedID: model.selectedHouseEdgeID,
                betSize: model.betSize,
                bets: model.sessionBets,
                totalWagered: model.totalAmountWagered,
                expectedCost: model.expectedHouseEdgeCost,
                onSelect: { model.selectHouseEdgeItem($0) },
                onBetSizeChange: { model.betSize = $0 },
                onBetsChange: { model.sessionBets = $0 },
                onFinish: {
                    Haptics.success()
                    withAnimation(.easeInOut(duration: 0.22)) { model.advance() }
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity
            ))

        case .finished:
            OnboardingCompleteView(
                highlights: completionHighlights,
                onRestart: {
                    withAnimation(.easeInOut(duration: 0.25)) { model.restart() }
                }
            )
            .transition(.opacity)
        }
    }

    /// Plain-language recap built from the user's answers.
    private var completionHighlights: [String] {
        var lines: [String] = []

        let familiarity = model.selection(for: "familiarity")
        if familiarity.contains("new") {
            lines.append("Explanations start with the basics, in plain language.")
        } else if familiarity.contains("confusing") {
            lines.append("Offer requirements are broken down step by step.")
        } else if familiarity.contains("organize") {
            lines.append("Essentials up front, with full terms a tap away.")
        }

        let priority = model.selection(for: "priority")
        if priority.contains("own-money") {
            lines.append("Qualifying deposit is shown first on every offer.")
        } else if priority.contains("playthrough") {
            lines.append("Total playthrough is shown next to every bonus.")
        } else if priority.contains("conditions") {
            lines.append("Bonus value and its conditions appear side by side.")
        } else if priority.contains("tracking") {
            lines.append("Your board leads with deposits and payouts.")
        }

        let location = model.selection(for: "location")
        if location.contains("mi") {
            lines.append("Journey and money tracking enabled for Michigan.")
        } else if location.contains("outside-mi") {
            lines.append("Money-tracking features enabled outside Michigan.")
        } else if location.contains("private") {
            lines.append("A money-tracking example is ready to explore.")
        }

        if lines.isEmpty {
            lines.append("Your sample board is ready to explore.")
        }
        return lines
    }
}

#Preview {
    OnboardingFlowView()
}
