//
//  OnboardingContent.swift
//  BankrollBoard
//

import Foundation

/// A single selectable answer inside a question step.
nonisolated struct OnboardingOption: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let symbol: String

    init(id: String, title: String, subtitle: String? = nil, symbol: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
    }
}

/// One question in the preference portion of onboarding.
nonisolated struct OnboardingQuestion: Identifiable, Hashable, Sendable {
    let id: String
    let eyebrow: String
    let title: String
    let prompt: String
    let options: [OnboardingOption]
    let allowsMultiple: Bool
    let footnote: String?
    let primaryActionTitle: String

    init(
        id: String,
        eyebrow: String,
        title: String,
        prompt: String,
        options: [OnboardingOption],
        allowsMultiple: Bool = false,
        footnote: String? = nil,
        primaryActionTitle: String = "Continue"
    ) {
        self.id = id
        self.eyebrow = eyebrow
        self.title = title
        self.prompt = prompt
        self.options = options
        self.allowsMultiple = allowsMultiple
        self.footnote = footnote
        self.primaryActionTitle = primaryActionTitle
    }
}

/// A sample casino offer used in the practice round comparison.
nonisolated struct SampleOffer: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let bonus: Int
    let deposit: Int
    let playthrough: Int

    /// Total wagering implied by the bonus and its playthrough multiplier.
    var totalWagering: Int { bonus * playthrough }
}

/// A game or bet shown in the house-edge practice round.
nonisolated struct HouseEdgeItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let detail: String
    let edge: Double

    /// Expected cost of the house edge across a session of flat bets.
    func expectedCost(betSize: Double, bets: Int) -> Double {
        betSize * Double(bets) * edge / 100
    }
}

/// Static copy for the onboarding flow.
nonisolated enum OnboardingContent {
    static let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: "motivation",
            eyebrow: "Make it worth your while",
            title: "What would make Bankroll Board worth it for you?",
            prompt: "Pick everything that applies. Then try a sample board for yourself.",
            options: [
                OnboardingOption(
                    id: "profit",
                    title: "Build as much profit as possible.",
                    subtitle: "Understand offer conditions and track actual results.",
                    symbol: "chart.line.uptrend.xyaxis"
                ),
                OnboardingOption(
                    id: "transactions",
                    title: "Track my transactions better.",
                    subtitle: "Keep casino deposits and payouts in one place.",
                    symbol: "arrow.left.arrow.right"
                ),
                OnboardingOption(
                    id: "plan",
                    title: "Find the best plan for acquiring offers.",
                    subtitle: "Review eligibility, requirements, and deadlines.",
                    symbol: "list.bullet.rectangle"
                ),
                OnboardingOption(
                    id: "community",
                    title: "Join a community with friends.",
                    subtitle: "Connect through invite-only communities.",
                    symbol: "person.2"
                )
            ],
            allowsMultiple: true,
            footnote: "Select at least one to continue."
        ),
        OnboardingQuestion(
            id: "familiarity",
            eyebrow: "Start where you are",
            title: "How familiar are you with casino welcome offers?",
            prompt: "We'll match the explanations to your experience.",
            options: [
                OnboardingOption(
                    id: "new",
                    title: "I'm new — start with the basics.",
                    subtitle: "A plain-language walkthrough.",
                    symbol: "sparkles"
                ),
                OnboardingOption(
                    id: "confusing",
                    title: "I've tried them, but the terms confuse me.",
                    subtitle: "Make the requirements easier to follow.",
                    symbol: "questionmark.circle"
                ),
                OnboardingOption(
                    id: "organize",
                    title: "I know the terms — help me organize.",
                    subtitle: "The essentials, with details a tap away.",
                    symbol: "square.stack"
                )
            ],
            footnote: "Choose one to continue."
        ),
        OnboardingQuestion(
            id: "priority",
            eyebrow: "The details that matter",
            title: "What matters most before you try a casino offer?",
            prompt: "Choose what you'd want to understand first.",
            options: [
                OnboardingOption(
                    id: "own-money",
                    title: "How much of my own money is required.",
                    subtitle: "Start with the qualifying deposit.",
                    symbol: "dollarsign.circle"
                ),
                OnboardingOption(
                    id: "playthrough",
                    title: "How much play is needed before withdrawal.",
                    subtitle: "Look beyond the bonus headline.",
                    symbol: "arrow.triangle.2.circlepath"
                ),
                OnboardingOption(
                    id: "conditions",
                    title: "What the bonus provides — and its conditions.",
                    subtitle: "See promotional value and requirements together.",
                    symbol: "doc.text.magnifyingglass"
                ),
                OnboardingOption(
                    id: "tracking",
                    title: "I mainly want to track casinos I already use.",
                    subtitle: "Focus on deposits and payouts.",
                    symbol: "tray.full"
                )
            ],
            footnote: "Choose one to continue."
        ),
        OnboardingQuestion(
            id: "approach",
            eyebrow: "Your approach",
            title: "Which best describes your approach to a session?",
            prompt: "No judgment — this helps us make the guidance useful.",
            options: [
                OnboardingOption(
                    id: "planned",
                    title: "I decide my budget and stopping point beforehand.",
                    subtitle: "Guidance stays out of the way.",
                    symbol: "target"
                ),
                OnboardingOption(
                    id: "rough",
                    title: "I have a rough plan and check as I go.",
                    subtitle: "Gentle checkpoints along the way.",
                    symbol: "flag"
                ),
                OnboardingOption(
                    id: "moment",
                    title: "I tend to decide in the moment.",
                    subtitle: "Quick limits before you start.",
                    symbol: "bolt"
                ),
                OnboardingOption(
                    id: "none",
                    title: "I haven't developed a routine yet.",
                    subtitle: "We'll suggest a simple one.",
                    symbol: "compass.drawing"
                )
            ],
            footnote: "Choose one to continue."
        ),
        OnboardingQuestion(
            id: "location",
            eyebrow: "The right features for you",
            title: "Where will you be using Bankroll Board?",
            prompt: "Journey currently covers Michigan casino offers. Your location helps us show the relevant features.",
            options: [
                OnboardingOption(
                    id: "mi",
                    title: "I'm 21+ and in Michigan.",
                    subtitle: "Journey and money tracking are available.",
                    symbol: "mappin.and.ellipse"
                ),
                OnboardingOption(
                    id: "outside-mi",
                    title: "I'm 21+ and outside Michigan.",
                    subtitle: "Explore the money-tracking features.",
                    symbol: "globe.americas"
                ),
                OnboardingOption(
                    id: "private",
                    title: "Neither / prefer not to say.",
                    subtitle: "See a money-tracking example.",
                    symbol: "lock"
                )
            ],
            footnote: "Operator eligibility and current terms still need to be checked.",
            primaryActionTitle: "Try my sample board"
        )
    ]

    static let offerA = SampleOffer(id: "a", label: "Sample offer A", bonus: 25, deposit: 50, playthrough: 10)
    static let offerB = SampleOffer(id: "b", label: "Sample offer B", bonus: 100, deposit: 50, playthrough: 30)

    static let houseEdgeItems: [HouseEdgeItem] = [
        HouseEdgeItem(id: "blackjack", name: "Blackjack", detail: "Favorable rules · basic strategy", edge: 0.28),
        HouseEdgeItem(id: "craps-pass", name: "Craps · Pass Line", detail: "Standard line bet · no odds", edge: 1.41),
        HouseEdgeItem(id: "craps-dont", name: "Craps · Don't Pass", detail: "12 pushes · no odds", edge: 1.36),
        HouseEdgeItem(id: "bacc-player", name: "Baccarat · Player", detail: "8 decks · ties push", edge: 1.24),
        HouseEdgeItem(id: "bacc-banker", name: "Baccarat · Banker", detail: "8 decks · 5% commission", edge: 1.06),
        HouseEdgeItem(id: "roulette", name: "Roulette · Double zero", detail: "38 pockets · any inside bet", edge: 5.26)
    ]
}
