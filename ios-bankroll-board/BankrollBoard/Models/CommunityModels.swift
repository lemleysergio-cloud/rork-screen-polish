//
//  CommunityModels.swift
//  BankrollBoard
//
//  Community data model: boards, timeframes, ranked profiles, and messages.
//

import Foundation

/// Which board the Community screen is showing.
nonisolated enum CommunityBoard: String, CaseIterable, Identifiable, Sendable {
    case publicBoard
    case privateBoard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .publicBoard: "Public"
        case .privateBoard: "Private"
        }
    }
}

/// Leaderboard windows, matching the web build's timeframe set.
nonisolated enum CommunityTimeframe: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case year
    case ytd
    case allTime

    var id: String { rawValue }

    var short: String {
        switch self {
        case .week: "7D"
        case .month: "30D"
        case .year: "365D"
        case .ytd: "YTD"
        case .allTime: "All"
        }
    }

    var long: String {
        switch self {
        case .week: "Last 7 days"
        case .month: "Last 30 days"
        case .year: "Last 365 days"
        case .ytd: "Year to date"
        case .allTime: "All time"
        }
    }

    /// Share of an all-time figure attributable to this window.
    var scale: Double {
        switch self {
        case .week: 0.08
        case .month: 0.26
        case .year: 0.78
        case .ytd: 0.61
        case .allTime: 1
        }
    }
}

/// Sort direction for the leaderboard.
nonisolated enum CommunityDirection: String, CaseIterable, Identifiable, Sendable {
    case up
    case down

    var id: String { rawValue }

    var title: String {
        switch self {
        case .up: "Up most"
        case .down: "Down most"
        }
    }
}

nonisolated struct CommunityProfile: Identifiable, Hashable, Sendable {
    let id: String
    let username: String
    let distinction: String
    /// Verified all-time cash flow inside Bankroll Board.
    let allTimeAmount: Int
    let isYou: Bool

    init(
        id: String,
        username: String,
        distinction: String,
        allTimeAmount: Int,
        isYou: Bool = false
    ) {
        self.id = id
        self.username = username
        self.distinction = distinction
        self.allTimeAmount = allTimeAmount
        self.isYou = isYou
    }

    /// Two-letter monogram used when no avatar image exists.
    var initials: String {
        let letters = username.filter { $0.isLetter || $0.isNumber }
        return String(letters.prefix(2)).uppercased()
    }
}

nonisolated struct CommunityRanking: Identifiable, Hashable, Sendable {
    let profile: CommunityProfile
    let rank: Int
    let amount: Int

    var id: String { profile.id }
}

nonisolated struct CommunityMessage: Identifiable, Hashable, Sendable {
    let id: String
    let username: String
    let body: String
    let sentAt: Date
    let isOwn: Bool
}

nonisolated struct CommunityGroup: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var memberCount: Int
    var isOwner: Bool
}

/// Illustrative Community content until the device is connected to the live board.
nonisolated enum CommunitySeed {
    static let me = CommunityProfile(
        id: "me",
        username: "Big_Serg",
        distinction: "Verified · 6 offers",
        allTimeAmount: 1840,
        isYou: true
    )

    static let winners: [CommunityProfile] = [
        .init(id: "p1", username: "QuietGrind", distinction: "Verified · 14 offers", allTimeAmount: 6420),
        .init(id: "p2", username: "MittenMoney", distinction: "Verified · 11 offers", allTimeAmount: 4870),
        .init(id: "p3", username: "Hedge_Hana", distinction: "Verified · 12 offers", allTimeAmount: 3960),
        .init(id: "p4", username: "LowVarianceLu", distinction: "Verified · 9 offers", allTimeAmount: 2740),
        .init(id: "p5", username: "NorthBankroll", distinction: "Verified · 7 offers", allTimeAmount: 2180),
        .init(id: "p6", username: "SlowRollSam", distinction: "Verified · 5 offers", allTimeAmount: 1290),
        .init(id: "p7", username: "Ledger_Kay", distinction: "Verified · 4 offers", allTimeAmount: 860)
    ]

    static let learners: [CommunityProfile] = [
        .init(id: "n1", username: "ChaseNoMore", distinction: "Verified · 8 offers", allTimeAmount: -2310),
        .init(id: "n2", username: "TiltTracker", distinction: "Verified · 6 offers", allTimeAmount: -1680),
        .init(id: "n3", username: "RiverRunner", distinction: "Verified · 5 offers", allTimeAmount: -1140),
        .init(id: "n4", username: "BlueLineBets", distinction: "Verified · 3 offers", allTimeAmount: -720),
        .init(id: "n5", username: "CautiousCaz", distinction: "Verified · 4 offers", allTimeAmount: -430)
    ]

    static let messages: [CommunityMessage] = [
        .init(
            id: "m1",
            username: "QuietGrind",
            body: "Finished the bet365 offer today. Logged every deposit as I went and the math lined up exactly with the estimate.",
            sentAt: Date(timeIntervalSinceNow: -5_400),
            isOwn: false
        ),
        .init(
            id: "m2",
            username: "LowVarianceLu",
            body: "Reminder for anyone starting: one signup bonus per casino across all states. I burned mine early and had to wait.",
            sentAt: Date(timeIntervalSinceNow: -14_100),
            isOwn: false
        ),
        .init(
            id: "m3",
            username: "Hedge_Hana",
            body: "Took a week off after a rough run. The pause button is part of the strategy, not a failure.",
            sentAt: Date(timeIntervalSinceNow: -96_000),
            isOwn: false
        )
    ]

    static let sampleGroup = CommunityGroup(
        id: "g-demo",
        name: "Friday Night Crew",
        memberCount: 6,
        isOwner: true
    )
}

/// Formats a signed dollar figure, e.g. `+$1,240` or `−$430`.
nonisolated func communityMoney(_ value: Int, showsPlus: Bool = true) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    let magnitude = abs(value)
    let digits = formatter.string(from: NSNumber(value: magnitude)) ?? String(magnitude)
    let sign = value < 0 ? "−" : (showsPlus && value > 0 ? "+" : "")
    return "\(sign)$\(digits)"
}

/// Short relative stamp such as `2h ago`, falling back to a date for older posts.
nonisolated func communityRelativeTime(_ date: Date, now: Date = Date()) -> String {
    let seconds = now.timeIntervalSince(date)
    if seconds < 60 { return "Just now" }
    if seconds < 3_600 { return "\(Int(seconds / 60))m ago" }
    if seconds < 86_400 { return "\(Int(seconds / 3_600))h ago" }
    if seconds < 604_800 { return "\(Int(seconds / 86_400))d ago" }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
}
