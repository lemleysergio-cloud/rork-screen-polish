//
//  CommunityViewModel.swift
//  BankrollBoard
//

import Foundation
import Observation

/// Drives the Community screen: board selection, consent-gated sharing,
/// leaderboard shaping, private groups, and the comment composer.
@Observable
final class CommunityViewModel {
    // MARK: - Board state

    var board: CommunityBoard = .publicBoard
    var timeframe: CommunityTimeframe = .week
    var direction: CommunityDirection = .up

    // MARK: - Consent

    /// Publishing to the public board. Off until the user explicitly opts in.
    private(set) var publicSharing: Bool = false
    /// Publishing inside the selected private group.
    private(set) var privateSharing: Bool = false
    private(set) var guidelinesAccepted: Bool = false

    // MARK: - Private communities

    private(set) var groups: [CommunityGroup] = []
    var selectedGroupID: String?

    // MARK: - Conversation

    private(set) var publicMessages: [CommunityMessage] = CommunitySeed.messages
    private(set) var privateMessages: [CommunityMessage] = []
    var draft: String = ""

    /// Cap mirrors the web composer.
    let messageLimit: Int = 500

    // MARK: - Derived

    var me: CommunityProfile { CommunitySeed.me }

    var selectedGroup: CommunityGroup? {
        guard let selectedGroupID else { return groups.first }
        return groups.first { $0.id == selectedGroupID }
    }

    /// Whether the active board currently accepts posts from this user.
    var canPost: Bool {
        switch board {
        case .publicBoard: publicSharing && guidelinesAccepted
        case .privateBoard: selectedGroup != nil && privateSharing && guidelinesAccepted
        }
    }

    /// Whether the active board is publishing this user's results.
    var isSharingOnActiveBoard: Bool {
        switch board {
        case .publicBoard: publicSharing
        case .privateBoard: privateSharing && selectedGroup != nil
        }
    }

    var statusChip: String {
        switch board {
        case .publicBoard: publicSharing ? "Sharing on" : "Browsing only"
        case .privateBoard: selectedGroup == nil ? "No groups yet" : (privateSharing ? "Sharing on" : "Invite-only")
        }
    }

    var messages: [CommunityMessage] {
        board == .publicBoard ? publicMessages : privateMessages
    }

    /// Ranked rows for the active board, timeframe, and direction.
    var rankings: [CommunityRanking] {
        var pool: [CommunityProfile] = direction == .up ? CommunitySeed.winners : CommunitySeed.learners

        if board == .privateBoard {
            guard let group = selectedGroup else { return [] }
            pool = Array(pool.prefix(max(0, group.memberCount - 1)))
        }

        if isSharingOnActiveBoard {
            pool.append(me)
        }

        let scaled: [(CommunityProfile, Int)] = pool.map { profile in
            (profile, Int((Double(profile.allTimeAmount) * timeframe.scale).rounded()))
        }

        let sorted = scaled.sorted { lhs, rhs in
            direction == .up ? lhs.1 > rhs.1 : lhs.1 < rhs.1
        }

        return sorted.enumerated().map { index, entry in
            CommunityRanking(profile: entry.0, rank: index + 1, amount: entry.1)
        }
    }

    /// The user's own row, when they are publishing to this board.
    var myRanking: CommunityRanking? {
        rankings.first { $0.profile.isYou }
    }

    var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSend: Bool {
        canPost && !trimmedDraft.isEmpty && trimmedDraft.count <= messageLimit
    }

    // MARK: - Intent

    func select(board newValue: CommunityBoard) {
        guard newValue != board else { return }
        board = newValue
    }

    func select(timeframe newValue: CommunityTimeframe) {
        guard newValue != timeframe else { return }
        timeframe = newValue
    }

    func select(direction newValue: CommunityDirection) {
        guard newValue != direction else { return }
        direction = newValue
    }

    func acceptGuidelines() {
        guidelinesAccepted = true
    }

    /// Enables sharing on the active board. Callers must collect consent first.
    func enableSharing() {
        guidelinesAccepted = true
        switch board {
        case .publicBoard: publicSharing = true
        case .privateBoard: privateSharing = true
        }
    }

    /// Stops publishing immediately, leaving the user in browse-only mode.
    func disableSharing() {
        switch board {
        case .publicBoard: publicSharing = false
        case .privateBoard: privateSharing = false
        }
    }

    func createGroup(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let group = CommunityGroup(
            id: "g-\(UUID().uuidString.prefix(8))",
            name: trimmed,
            memberCount: 1,
            isOwner: true
        )
        groups.append(group)
        selectedGroupID = group.id
    }

    func joinSampleGroup() {
        guard !groups.contains(where: { $0.id == CommunitySeed.sampleGroup.id }) else { return }
        groups.append(CommunitySeed.sampleGroup)
        selectedGroupID = CommunitySeed.sampleGroup.id
    }

    func leaveSelectedGroup() {
        guard let group = selectedGroup else { return }
        groups.removeAll { $0.id == group.id }
        selectedGroupID = groups.first?.id
        if groups.isEmpty { privateSharing = false }
    }

    func send() {
        guard canSend else { return }
        let message = CommunityMessage(
            id: UUID().uuidString,
            username: me.username,
            body: trimmedDraft,
            sentAt: Date(),
            isOwn: true
        )
        switch board {
        case .publicBoard: publicMessages.insert(message, at: 0)
        case .privateBoard: privateMessages.insert(message, at: 0)
        }
        draft = ""
    }

    func delete(messageID: String) {
        publicMessages.removeAll { $0.id == messageID }
        privateMessages.removeAll { $0.id == messageID }
    }
}
