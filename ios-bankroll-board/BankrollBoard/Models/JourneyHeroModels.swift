//
//  JourneyHeroModels.swift
//  BankrollBoard
//
//  Journey hero data model: state rankings, casino catalog, progress-driven
//  node states, and the five-slot orbit view model.
//

import Combine
import SwiftUI

enum JourneyStateCode: String, CaseIterable, Identifiable {
    case MI, NJ, PA, WV

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .MI: return "Michigan"
        case .NJ: return "New Jersey"
        case .PA: return "Pennsylvania"
        case .WV: return "West Virginia"
        }
    }
}

enum JourneyProgressStatus: Equatable {
    case active
    case completed
    case alreadyUsed
    case skipped
    case ineligible
    case unavailable
}

enum JourneyNodeState: String {
    case completed
    case current
    case active
    case next
    case locked

    var label: String {
        switch self {
        case .completed: return "Completed"
        case .current: return "You are here"
        case .active: return "Active"
        case .next: return "Next"
        case .locked: return "Future"
        }
    }
}

struct JourneyCasino: Identifiable, Hashable {
    let operatorId: String
    let name: String
    let logoAssetName: String?
    let brandColorHex: UInt32
    let fresh: Bool

    var id: String { operatorId }
}

struct JourneyVisibleNode: Identifiable {
    let casino: JourneyCasino
    let rank: Int
    let state: JourneyNodeState
    let slot: Int
    let relativeOffset: Int

    var id: String { casino.operatorId }
}

enum JourneyCatalog {
    static let rankings: [JourneyStateCode: [String]] = [
        .MI: ["fanduel", "betmgm", "bet365", "hard-rock", "draftkings", "fanatics", "caesars", "horseshoe", "betrivers", "golden-nugget", "playgunlake"],
        .NJ: ["betmgm", "fanduel", "borgata", "draftkings", "bet365", "fanatics", "hard-rock", "betparx", "bally", "caesars", "playstar", "monopoly"],
        .PA: ["fanduel", "betmgm", "bet365", "hollywood", "draftkings", "fanatics", "caesars", "borgata", "betrivers", "betparx", "golden-nugget", "monopoly"],
        .WV: ["fanduel", "betmgm", "bet365", "draftkings", "fanatics", "caesars", "betrivers"]
    ]

    static let casinos: [String: JourneyCasino] = {
        let values: [JourneyCasino] = [
            .init(operatorId: "fanduel", name: "FanDuel Casino", logoAssetName: "fanduel", brandColorHex: 0x1493FF, fresh: true),
            .init(operatorId: "betmgm", name: "BetMGM", logoAssetName: "betmgm", brandColorHex: 0xC9A84C, fresh: true),
            .init(operatorId: "bet365", name: "bet365 Casino", logoAssetName: "bet365", brandColorHex: 0x087B5A, fresh: true),
            .init(operatorId: "hard-rock", name: "Hard Rock Bet", logoAssetName: "hardrockcasino", brandColorHex: 0xE8C34A, fresh: true),
            .init(operatorId: "draftkings", name: "DraftKings Casino", logoAssetName: "draftkingscasino", brandColorHex: 0x53D337, fresh: true),
            .init(operatorId: "fanatics", name: "Fanatics Casino", logoAssetName: "fanatics", brandColorHex: 0xE21D2B, fresh: true),
            .init(operatorId: "caesars", name: "Caesars Palace", logoAssetName: "caesars", brandColorHex: 0xC70000, fresh: true),
            .init(operatorId: "horseshoe", name: "Horseshoe Online Casino", logoAssetName: "horseshoe", brandColorHex: 0xBD8B2F, fresh: true),
            .init(operatorId: "betrivers", name: "BetRivers Casino", logoAssetName: "betrivers", brandColorHex: 0x193B6A, fresh: true),
            .init(operatorId: "golden-nugget", name: "Golden Nugget", logoAssetName: "golden_nugget_casino", brandColorHex: 0xC5A13E, fresh: true),
            .init(operatorId: "playgunlake", name: "Play Gun Lake", logoAssetName: "playgunlake", brandColorHex: 0xC7A25C, fresh: true),
            .init(operatorId: "borgata", name: "Borgata Casino", logoAssetName: "borgata", brandColorHex: 0xB99A61, fresh: true),
            .init(operatorId: "betparx", name: "betPARX Casino", logoAssetName: "betparx", brandColorHex: 0x153849, fresh: true),
            .init(operatorId: "bally", name: "Bally Bet Casino", logoAssetName: "ballybet", brandColorHex: 0xD62B34, fresh: true),
            .init(operatorId: "playstar", name: "PlayStar Casino", logoAssetName: "playstar", brandColorHex: 0x54238B, fresh: true),
            .init(operatorId: "monopoly", name: "Monopoly Casino", logoAssetName: "monopoly", brandColorHex: 0xC92228, fresh: true),
            .init(operatorId: "hollywood", name: "Hollywood Casino", logoAssetName: "hollywoodcasino", brandColorHex: 0x9C2235, fresh: true)
        ]
        return Dictionary(uniqueKeysWithValues: values.map { ($0.operatorId, $0) })
    }()

    static func rankedCasinos(for state: JourneyStateCode) -> [JourneyCasino] {
        rankings[state, default: []].compactMap { casinos[$0] }
    }
}

@MainActor
final class JourneyOrbitViewModel: ObservableObject {
    @Published var selectedState: JourneyStateCode
    @Published private(set) var focusIndex: Int = 0
    @Published var progressByOperator: [String: JourneyProgressStatus]

    init(
        selectedState: JourneyStateCode = .MI,
        progressByOperator: [String: JourneyProgressStatus] = [:]
    ) {
        self.selectedState = selectedState
        self.progressByOperator = progressByOperator
        focusIndex = Self.initialFocusIndex(
            casinos: JourneyCatalog.rankedCasinos(for: selectedState),
            progress: progressByOperator
        )
    }

    var casinos: [JourneyCasino] {
        JourneyCatalog.rankedCasinos(for: selectedState)
    }

    var completedCount: Int {
        casinos.filter {
            progressByOperator[$0.operatorId] == .completed ||
            progressByOperator[$0.operatorId] == .alreadyUsed
        }.count
    }

    var currentOperatorId: String? {
        if let active = casinos.first(where: { progressByOperator[$0.operatorId] == .active }) {
            return active.operatorId
        }
        return casinos.first(where: isEligible)?.operatorId
    }

    var nextOperatorId: String? {
        guard
            let currentOperatorId,
            let currentIndex = casinos.firstIndex(where: { $0.operatorId == currentOperatorId })
        else { return nil }

        return casinos.dropFirst(currentIndex + 1)
            .first(where: isEligible)?
            .operatorId
    }

    var focusedCasino: JourneyCasino? {
        guard casinos.indices.contains(focusIndex) else { return nil }
        return casinos[focusIndex]
    }

    var visibleNodes: [JourneyVisibleNode] {
        guard !casinos.isEmpty else { return [] }
        let radius = min(2, casinos.count / 2)
        var seen = Set<Int>()
        var result: [JourneyVisibleNode] = []

        for offset in (-radius)...radius {
            let index = wrapped(focusIndex + offset, count: casinos.count)
            guard seen.insert(index).inserted else { continue }
            let casino = casinos[index]
            result.append(
                JourneyVisibleNode(
                    casino: casino,
                    rank: index + 1,
                    state: nodeState(for: casino),
                    slot: offset + 2,
                    relativeOffset: offset
                )
            )
        }
        return result
    }

    func selectState(_ state: JourneyStateCode) {
        selectedState = state
        focusIndex = Self.initialFocusIndex(
            casinos: JourneyCatalog.rankedCasinos(for: state),
            progress: progressByOperator
        )
    }

    func move(by delta: Int) {
        guard !casinos.isEmpty else { return }
        focusIndex = wrapped(focusIndex + delta, count: casinos.count)
    }

    func focus(operatorId: String) {
        guard let index = casinos.firstIndex(where: { $0.operatorId == operatorId }) else { return }
        focusIndex = index
    }

    private func nodeState(for casino: JourneyCasino) -> JourneyNodeState {
        let progress = progressByOperator[casino.operatorId]
        if progress == .completed || progress == .alreadyUsed { return .completed }
        if casino.operatorId == currentOperatorId { return .current }
        if progress == .active { return .active }
        if casino.operatorId == nextOperatorId { return .next }
        return .locked
    }

    private func isEligible(_ casino: JourneyCasino) -> Bool {
        guard casino.fresh else { return false }
        switch progressByOperator[casino.operatorId] {
        case .completed, .alreadyUsed, .skipped, .ineligible, .unavailable:
            return false
        case .active, .none:
            return true
        }
    }

    private func wrapped(_ value: Int, count: Int) -> Int {
        (value % count + count) % count
    }

    private static func initialFocusIndex(
        casinos: [JourneyCasino],
        progress: [String: JourneyProgressStatus]
    ) -> Int {
        if let active = casinos.firstIndex(where: { progress[$0.operatorId] == .active }) {
            return active
        }
        if let eligible = casinos.firstIndex(where: {
            guard $0.fresh else { return false }
            switch progress[$0.operatorId] {
            case .completed, .alreadyUsed, .skipped, .ineligible, .unavailable:
                return false
            case .active, .none:
                return true
            }
        }) {
            return eligible
        }
        return 0
    }
}

extension Color {
    init(rgb: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xff) / 255,
            green: Double((rgb >> 8) & 0xff) / 255,
            blue: Double(rgb & 0xff) / 255,
            opacity: opacity
        )
    }
}
