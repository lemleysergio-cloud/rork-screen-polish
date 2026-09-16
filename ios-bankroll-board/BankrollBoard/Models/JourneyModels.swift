//
//  JourneyModels.swift
//  BankrollBoard
//

import Foundation

/// Where an offer sits in the player's journey.
nonisolated enum JourneyOfferState: String, Sendable, Hashable {
    case completed
    case current
    case next
    case ready
    case future

    /// Sentence-case label used in trail cards.
    var trailLabel: String {
        switch self {
        case .completed: "Completed"
        case .current: "You are here"
        case .next: "Next stop"
        case .ready: "Ready"
        case .future: "Future"
        }
    }

    /// Compact all-caps label used on orbit nodes.
    var nodeLabel: String {
        switch self {
        case .completed: "Done"
        case .current: "You are here"
        case .next: "Next"
        case .ready: "Ready"
        case .future: "Future"
        }
    }
}

/// Brand tile colors for an operator, stored as hex so the model stays `Sendable`.
nonisolated struct JourneyBrandMark: Sendable, Hashable {
    let top: UInt32
    let bottom: UInt32
    let ink: UInt32
    let monogram: String
}

/// A casino offer plotted on the journey.
nonisolated struct JourneyOffer: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    /// Name trimmed for the orbit node label.
    let shortName: String
    let mark: JourneyBrandMark
    /// Best-offer rank. `nil` means the offer is mapped but unranked.
    let rank: Int?
    let state: JourneyOfferState
    let headline: String
    let youPutIn: String
    let youMayReceive: String
    let mainCatch: String
    let verified: Bool
    let officialURL: String

    var rankLabel: String {
        guard let rank else { return "Additional offer" }
        return "Rank \(rank)"
    }

    var trailMarker: String {
        guard let rank else { return "•" }
        return String(format: "%02d", rank)
    }

    var verificationLabel: String {
        verified ? "Recently verified" : "Verify terms"
    }

    var isActiveProgress: Bool {
        state == .current || state == .completed
    }
}

/// A state a player can browse bonuses in.
nonisolated struct JourneyRegion: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let helpURL: String
}

/// A collectible stamp awarded for verified results.
nonisolated struct JourneyStamp: Identifiable, Sendable, Hashable {
    let id: String
    /// Large glyph inside the stamp frame, e.g. "1", "$100", "10%".
    let symbol: String
    let title: String
    let family: String
    let earned: Bool
}

/// Trail list filters.
nonisolated enum JourneyFilter: String, CaseIterable, Identifiable, Sendable {
    case best
    case active
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .best: "Best Offers"
        case .active: "Active"
        case .all: "All Offers"
        }
    }
}

/// Money summary shown above the trail.
nonisolated struct JourneyMoney: Sendable, Hashable {
    let verifiedNetProfit: Int
    let remainingOpportunity: Int
    let completedInRegion: Int
    let totalInRegion: Int
    let completedAllRegions: Int
}
