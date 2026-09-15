//
//  OnboardingViewModel.swift
//  BankrollBoard
//

import Foundation
import Observation

/// Drives the 7-step onboarding flow: 5 preference questions plus 2 practice rounds.
@Observable
final class OnboardingViewModel {
    /// Which screen of the flow is showing.
    enum Stage: Equatable {
        case question(Int)
        case offerComparison
        case houseEdge
        case finished
    }

    let questions: [OnboardingQuestion] = OnboardingContent.questions

    private(set) var stage: Stage = .question(0)
    private(set) var answers: [String: Set<String>] = [:]

    // Practice round 1
    private(set) var offerGuess: String?
    private(set) var showsOfferExplanation: Bool = false

    // Practice round 2
    private(set) var selectedHouseEdgeID: String = OnboardingContent.houseEdgeItems[0].id
    var sessionBets: Double = 100
    var betSize: Double = 10

    var totalSteps: Int { questions.count + 2 }

    /// 1-based index of the current step for the progress bar.
    var currentStep: Int {
        switch stage {
        case .question(let index): index + 1
        case .offerComparison: questions.count + 1
        case .houseEdge, .finished: totalSteps
        }
    }

    var sectionLabel: String {
        switch stage {
        case .question: "Your preferences"
        case .offerComparison, .houseEdge, .finished: "Try your board"
        }
    }

    var currentQuestion: OnboardingQuestion? {
        if case .question(let index) = stage, questions.indices.contains(index) {
            return questions[index]
        }
        return nil
    }

    var canGoBack: Bool {
        stage != .question(0)
    }

    // MARK: - Answers

    func selection(for questionID: String) -> Set<String> {
        answers[questionID] ?? []
    }

    func isSelected(questionID: String, optionID: String) -> Bool {
        selection(for: questionID).contains(optionID)
    }

    func toggle(questionID: String, optionID: String, allowsMultiple: Bool) {
        var current = selection(for: questionID)
        if allowsMultiple {
            if current.contains(optionID) {
                current.remove(optionID)
            } else {
                current.insert(optionID)
            }
        } else {
            current = current.contains(optionID) ? [] : [optionID]
        }
        answers[questionID] = current
    }

    /// The primary CTA stays disabled until the current question has an answer.
    var canAdvance: Bool {
        switch stage {
        case .question(let index):
            guard questions.indices.contains(index) else { return false }
            return !selection(for: questions[index].id).isEmpty
        case .offerComparison:
            return offerGuess != nil
        case .houseEdge, .finished:
            return true
        }
    }

    // MARK: - Navigation

    func advance() {
        switch stage {
        case .question(let index):
            stage = index + 1 < questions.count ? .question(index + 1) : .offerComparison
        case .offerComparison:
            stage = .houseEdge
        case .houseEdge:
            stage = .finished
        case .finished:
            break
        }
    }

    func goBack() {
        switch stage {
        case .question(let index):
            if index > 0 { stage = .question(index - 1) }
        case .offerComparison:
            stage = .question(questions.count - 1)
        case .houseEdge:
            stage = .offerComparison
        case .finished:
            stage = .houseEdge
        }
    }

    func restart() {
        stage = .question(0)
        answers = [:]
        offerGuess = nil
        showsOfferExplanation = false
        selectedHouseEdgeID = OnboardingContent.houseEdgeItems[0].id
    }

    // MARK: - Practice round 1

    /// The offer with lower total wagering is the correct answer.
    var correctOfferID: String {
        OnboardingContent.offerA.totalWagering <= OnboardingContent.offerB.totalWagering
            ? OnboardingContent.offerA.id
            : OnboardingContent.offerB.id
    }

    var isOfferGuessCorrect: Bool? {
        guard let offerGuess else { return nil }
        return offerGuess == correctOfferID
    }

    func chooseOffer(_ id: String) {
        offerGuess = id
        showsOfferExplanation = true
    }

    func revealOfferComparison() {
        showsOfferExplanation = true
    }

    // MARK: - Practice round 2

    var selectedHouseEdgeItem: HouseEdgeItem {
        OnboardingContent.houseEdgeItems.first { $0.id == selectedHouseEdgeID }
            ?? OnboardingContent.houseEdgeItems[0]
    }

    var expectedHouseEdgeCost: Double {
        selectedHouseEdgeItem.expectedCost(betSize: betSize, bets: Int(sessionBets))
    }

    var totalAmountWagered: Double {
        betSize * sessionBets
    }

    func selectHouseEdgeItem(_ id: String) {
        selectedHouseEdgeID = id
    }
}
