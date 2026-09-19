//
//  CommunityScreen.swift
//  BankrollBoard
//
//  Community: public and private leaderboards with consent-gated sharing,
//  a comment thread, and safety controls.
//

import SwiftUI

struct CommunityScreen: View {
    @State private var model = CommunityViewModel()
    @State private var showingConsent = false
    @State private var showingGuidelines = false
    @State private var showingCreateGroup = false
    @State private var showingRankingNote = false
    @State private var showingMessageActions = false
    @State private var messageTarget: CommunityMessage?
    @State private var newGroupName: String = ""
    @FocusState private var composerFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [JourneyPalette.canvasDeep, JourneyPalette.canvas, Color(rgb: 0x132F20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, BBTheme.screenMargin)
                        .padding(.top, 44)

                    boardTabs
                        .padding(.top, 20)

                    statusNotice

                    if model.board == .privateBoard && model.groups.isEmpty {
                        privateEmptyState
                            .padding(.horizontal, BBTheme.screenMargin)
                            .padding(.top, 22)
                    } else {
                        rankingsSection
                            .padding(.top, 26)

                        Divider()
                            .overlay(Color.white.opacity(0.14))
                            .padding(.horizontal, BBTheme.screenMargin)
                            .padding(.top, 28)

                        commentsSection
                            .padding(.top, 24)
                    }

                    safetyFooter
                        .padding(.top, 30)
                }
                .padding(.bottom, 130)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("community.page")
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingConsent) {
            CommunityConsentSheet(
                board: model.board,
                needsGuidelines: !model.guidelinesAccepted,
                onOpenGuidelines: {
                    showingConsent = false
                    showingGuidelines = true
                },
                onConfirm: {
                    Haptics.success()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        model.enableSharing()
                    }
                    showingConsent = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingGuidelines) {
            CommunityGuidelinesSheet(
                isAccepted: model.guidelinesAccepted,
                onAccept: {
                    Haptics.tap()
                    model.acceptGuidelines()
                    showingGuidelines = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingCreateGroup) {
            CommunityCreateGroupSheet(name: $newGroupName) {
                Haptics.success()
                model.createGroup(named: newGroupName)
                newGroupName = ""
                showingCreateGroup = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            messageTarget.map { "@\($0.username)" } ?? "Message",
            isPresented: $showingMessageActions,
            titleVisibility: .visible
        ) {
            if let target = messageTarget {
                if target.isOwn {
                    Button("Delete comment", role: .destructive) {
                        Haptics.warning()
                        model.delete(messageID: target.id)
                    }
                } else {
                    Button("Report comment") { Haptics.tap() }
                    Button("Block @\(target.username)", role: .destructive) { Haptics.warning() }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Reports are confidential and go to the moderation queue.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Text("COMMUNITY")
                    .font(.system(size: 11, weight: .black))
                    .kerning(1.4)
                    .foregroundStyle(JourneyPalette.gold)

                Spacer(minLength: 8)

                Text(model.statusChip)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(model.isSharingOnActiveBoard ? JourneyPalette.success : BBTheme.inkMuted)
                    .padding(.horizontal, 11)
                    .frame(height: 28)
                    .background {
                        Capsule()
                            .fill(model.isSharingOnActiveBoard ? JourneyPalette.success.opacity(0.13) : Color.white.opacity(0.05))
                            .overlay {
                                Capsule().stroke(
                                    model.isSharingOnActiveBoard ? JourneyPalette.success.opacity(0.4) : BBTheme.hairline.opacity(0.7),
                                    lineWidth: 1
                                )
                            }
                    }
            }

            HStack(alignment: .center, spacing: 16) {
                identityAvatar

                VStack(alignment: .leading, spacing: 1) {
                    Text("Community")
                        .font(.system(size: 40, weight: .regular, design: .serif))
                        .foregroundStyle(JourneyPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("@\(model.me.username) · \(model.me.distinction)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(JourneyPalette.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var identityAvatar: some View {
        ZStack {
            Circle()
                .stroke(JourneyPalette.gold.opacity(0.35), lineWidth: 1.5)
                .background(Circle().fill(Color(rgb: 0x193424)))
                .shadow(color: JourneyPalette.gold.opacity(0.12), radius: 12)

            Text(model.me.initials)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Color(rgb: 0xF4E8B2))
        }
        .frame(width: 64, height: 64)
        .accessibilityHidden(true)
    }

    // MARK: - Board tabs

    private var boardTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(CommunityBoard.allCases) { tab in
                    let isActive = model.board == tab
                    Button {
                        Haptics.selection()
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) {
                            model.select(board: tab)
                        }
                    } label: {
                        VStack(spacing: 9) {
                            Text(tab.title)
                                .font(.system(size: 15, weight: isActive ? .semibold : .regular))
                                .foregroundStyle(isActive ? JourneyPalette.ink : BBTheme.inkMuted)

                            Rectangle()
                                .fill(isActive ? JourneyPalette.gold : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 46, alignment: .bottom)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(BBPressStyle())
                    .accessibilityAddTraits(isActive ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, BBTheme.screenMargin)

            Rectangle()
                .fill(BBTheme.hairline.opacity(0.5))
                .frame(height: 1)
        }
    }

    // MARK: - Status notice

    @ViewBuilder
    private var statusNotice: some View {
        if !model.isSharingOnActiveBoard && !(model.board == .privateBoard && model.groups.isEmpty) {
            noticeStrip(
                symbol: "eye",
                title: model.board == .publicBoard ? "You're browsing only" : "Hidden in this group",
                body: model.board == .publicBoard
                    ? "Your results stay private until you choose to share them. Turn sharing on to appear on the board and join the conversation."
                    : "Only members of \(model.selectedGroup?.name ?? "this group") would see your results. Sharing is off right now.",
                actionTitle: "Turn on sharing"
            ) {
                Haptics.tap()
                showingConsent = true
            }
            .padding(.horizontal, BBTheme.screenMargin)
            .padding(.top, 18)
        }
    }

    private func noticeStrip(
        symbol: String,
        title: String,
        body: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(JourneyPalette.gold)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(JourneyPalette.ink)
            }

            Text(body)
                .font(.system(size: 12))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                Text(actionTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(JourneyPalette.canvasDeep)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background {
                        Capsule().fill(JourneyPalette.gold)
                    }
            }
            .buttonStyle(BBPressStyle())
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.035))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(JourneyPalette.gold.opacity(0.28), lineWidth: 1)
                }
        }
    }

    // MARK: - Rankings

    private var rankingsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            JourneySectionHeading(
                index: "01 / Leaderboard",
                title: "Rankings",
                caption: "Verified casino cash flow logged inside Bankroll Board."
            ) {
                Text(model.timeframe.long)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(JourneyPalette.gold)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background {
                        Capsule().stroke(JourneyPalette.gold.opacity(0.35), lineWidth: 1)
                    }
                    .padding(.top, 20)
            }

            directionControl
                .padding(.horizontal, BBTheme.screenMargin)

            timeframePills

            if model.rankings.isEmpty {
                emptyRankings
                    .padding(.horizontal, BBTheme.screenMargin)
            } else {
                VStack(spacing: 8) {
                    ForEach(model.rankings) { ranking in
                        rankingRow(ranking)
                    }
                }
                .padding(.horizontal, BBTheme.screenMargin)
            }

            rankingNote
                .padding(.horizontal, BBTheme.screenMargin)
        }
    }

    private var directionControl: some View {
        HStack(spacing: 4) {
            ForEach(CommunityDirection.allCases) { option in
                let isActive = model.direction == option
                Button {
                    Haptics.selection()
                    withAnimation(.easeOut(duration: 0.2)) {
                        model.select(direction: option)
                    }
                } label: {
                    Text(option.title)
                        .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? JourneyPalette.canvasDeep : BBTheme.inkMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isActive ? JourneyPalette.gold : Color.clear)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(BBPressStyle())
                .accessibilityAddTraits(isActive ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(BBTheme.hairline.opacity(0.55), lineWidth: 1)
                }
        }
    }

    private var timeframePills: some View {
        HStack(spacing: 7) {
            ForEach(CommunityTimeframe.allCases) { option in
                let isActive = model.timeframe == option
                Button {
                    Haptics.selection()
                    withAnimation(.easeOut(duration: 0.2)) {
                        model.select(timeframe: option)
                    }
                } label: {
                    Text(option.short)
                        .font(.system(size: 12, weight: isActive ? .bold : .medium))
                        .foregroundStyle(isActive ? JourneyPalette.gold : BBTheme.inkMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isActive ? JourneyPalette.gold.opacity(0.13) : Color.clear)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            isActive ? JourneyPalette.gold.opacity(0.45) : BBTheme.hairline.opacity(0.5),
                                            lineWidth: 1
                                        )
                                }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(BBPressStyle())
                .accessibilityLabel(option.long)
                .accessibilityAddTraits(isActive ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }

    private func rankingRow(_ ranking: CommunityRanking) -> some View {
        let isPodium = ranking.rank <= 3
        let isYou = ranking.profile.isYou

        return HStack(spacing: 13) {
            Text("\(ranking.rank)")
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .monospacedDigit()
                .foregroundStyle(isPodium ? Color(rgb: 0xF4E8B2) : BBTheme.inkMuted)
                .frame(width: 22, alignment: .trailing)

            ZStack {
                Circle().fill(Color(rgb: 0x1C2E22))
                Circle().stroke(
                    isPodium ? JourneyPalette.gold.opacity(0.55) : BBTheme.hairline.opacity(0.7),
                    lineWidth: 1
                )
                Text(ranking.profile.initials)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isPodium ? Color(rgb: 0xF4E8B2) : BBTheme.inkMuted)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("@\(ranking.profile.username)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(JourneyPalette.ink)
                        .lineLimit(1)

                    if isYou {
                        Text("You")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(JourneyPalette.canvasDeep)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background { Capsule().fill(JourneyPalette.gold) }
                    }
                }

                Text(ranking.profile.distinction)
                    .font(.system(size: 11))
                    .foregroundStyle(BBTheme.inkMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(communityMoney(ranking.amount))
                .font(.system(size: 16, weight: .regular, design: .serif))
                .monospacedDigit()
                .foregroundStyle(ranking.amount < 0 ? Color(rgb: 0xE08B7A) : JourneyPalette.success)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(isYou ? JourneyPalette.gold.opacity(0.08) : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isYou ? JourneyPalette.gold.opacity(0.35) : Color.clear, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Rank \(ranking.rank), \(ranking.profile.username), \(communityMoney(ranking.amount))"
        )
    }

    private var emptyRankings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nothing on this board yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(JourneyPalette.ink)
            Text("Once members share their verified results, they appear here ranked by cash flow.")
                .font(.system(size: 12))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .stroke(BBTheme.hairline.opacity(0.55), style: .init(lineWidth: 1, dash: [5, 4]))
        }
    }

    private var rankingNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.22)) {
                    showingRankingNote.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("How these rankings work")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(JourneyPalette.gold)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(JourneyPalette.gold)
                        .rotationEffect(.degrees(showingRankingNote ? 180 : 0))
                    Spacer()
                }
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(BBPressStyle())

            if showingRankingNote {
                Text("Amounts are verified casino and sportsbook cash flow recorded inside Bankroll Board — not a bank balance. Figures are estimates over the selected window and are never a prediction of future results. Only members who opted in appear here.")
                    .font(.system(size: 11))
                    .foregroundStyle(BBTheme.inkMuted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Private empty state

    private var privateEmptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Private boards")
                .font(BBTheme.headline(26))
                .foregroundStyle(JourneyPalette.ink)

            Text("Create a small board for friends, or join one with an invite. Results you share here stay inside the group and never reach the public board.")
                .font(.system(size: 13))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    showingCreateGroup = true
                } label: {
                    Text("Create a community")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(JourneyPalette.canvasDeep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background { RoundedRectangle(cornerRadius: 16).fill(JourneyPalette.gold) }
                }
                .buttonStyle(BBPressStyle())

                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        model.joinSampleGroup()
                    }
                } label: {
                    Text("Join with an invite")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(JourneyPalette.gold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(JourneyPalette.gold.opacity(0.45), lineWidth: 1)
                        }
                }
                .buttonStyle(BBPressStyle())
            }
            .padding(.top, 4)

            Text("You can own up to five communities with 50 members each.")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.035))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(BBTheme.hairline.opacity(0.6), lineWidth: 1)
                }
        }
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            JourneySectionHeading(
                index: model.board == .publicBoard ? "02 / Discussion" : "02 / Group chat",
                title: model.board == .publicBoard ? "Comments" : (model.selectedGroup?.name ?? "Private chat"),
                caption: "Support and accountability. No wagering advice, no pressure to play."
            ) {
                EmptyView()
            }

            composer
                .padding(.horizontal, BBTheme.screenMargin)

            if model.messages.isEmpty {
                emptyComments
                    .padding(.horizontal, BBTheme.screenMargin)
            } else {
                VStack(spacing: 12) {
                    ForEach(model.messages) { message in
                        messageRow(message)
                    }
                }
                .padding(.horizontal, BBTheme.screenMargin)
            }
        }
    }

    @ViewBuilder
    private var composer: some View {
        if model.canPost {
            VStack(alignment: .leading, spacing: 10) {
                TextField(
                    "Share something useful…",
                    text: Binding(
                        get: { model.draft },
                        set: { model.draft = $0 }
                    ),
                    axis: .vertical
                )
                .font(.system(size: 14))
                .foregroundStyle(JourneyPalette.ink)
                .tint(JourneyPalette.gold)
                .lineLimit(1...6)
                .focused($composerFocused)
                .accessibilityIdentifier("community.composer")

                HStack {
                    Text("\(model.trimmedDraft.count)/\(model.messageLimit)")
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundStyle(
                            model.trimmedDraft.count > model.messageLimit
                                ? Color(rgb: 0xE08B7A)
                                : BBTheme.inkMuted
                        )

                    Spacer()

                    Button {
                        Haptics.success()
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.85)) {
                            model.send()
                        }
                        composerFocused = false
                    } label: {
                        Text("Post")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(model.canSend ? JourneyPalette.canvasDeep : BBTheme.inkMuted)
                            .padding(.horizontal, 18)
                            .frame(height: 38)
                            .background {
                                Capsule()
                                    .fill(model.canSend ? JourneyPalette.gold : Color.white.opacity(0.06))
                            }
                    }
                    .buttonStyle(BBPressStyle())
                    .disabled(!model.canSend)
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.045))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(BBTheme.hairline.opacity(0.6), lineWidth: 1)
                    }
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "lock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BBTheme.inkMuted)

                Text(
                    model.board == .privateBoard && model.selectedGroup == nil
                        ? "Join or create a group to chat."
                        : "Turn on sharing to join the conversation."
                )
                .font(.system(size: 13))
                .foregroundStyle(BBTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Button {
                    Haptics.tap()
                    if model.board == .privateBoard && model.selectedGroup == nil {
                        showingCreateGroup = true
                    } else {
                        showingConsent = true
                    }
                } label: {
                    Text(model.board == .privateBoard && model.selectedGroup == nil ? "Create" : "Enable")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(JourneyPalette.gold)
                }
                .buttonStyle(BBPressStyle())
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(BBTheme.hairline.opacity(0.55), style: .init(lineWidth: 1, dash: [5, 4]))
            }
        }
    }

    private func messageRow(_ message: CommunityMessage) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text("@\(message.username)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(message.isOwn ? Color(rgb: 0xF4E8B2) : JourneyPalette.ink)

                Text(communityRelativeTime(message.sentAt))
                    .font(.system(size: 11))
                    .foregroundStyle(BBTheme.inkMuted)

                Spacer(minLength: 4)

                Button {
                    Haptics.tap()
                    messageTarget = message
                    showingMessageActions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BBTheme.inkMuted)
                        .frame(width: 44, height: 30, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BBPressStyle())
                .accessibilityLabel("Options for comment by \(message.username)")
            }

            Text(message.body)
                .font(.system(size: 14))
                .foregroundStyle(Color(rgb: 0xD6DDD1))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(message.isOwn ? 0.055 : 0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            message.isOwn ? JourneyPalette.gold.opacity(0.3) : BBTheme.hairline.opacity(0.5),
                            lineWidth: 1
                        )
                }
        }
    }

    private var emptyComments: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No comments yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(JourneyPalette.ink)
            Text("Be the first to post. A short note about what worked for you goes a long way.")
                .font(.system(size: 12))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .stroke(BBTheme.hairline.opacity(0.55), style: .init(lineWidth: 1, dash: [5, 4]))
        }
    }

    // MARK: - Footer

    private var safetyFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your privacy stays yours.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(rgb: 0xD6DDD1))

            Text("Bankroll Board never publishes your legal name, email, phone, date of birth, bank connections, or raw transactions. You can turn sharing off at any moment.")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    showingGuidelines = true
                } label: {
                    Text("Community Guidelines")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(BBTheme.gold)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(BBTheme.hairline.opacity(0.6), lineWidth: 1)
                        }
                }
                .buttonStyle(BBPressStyle())

                if model.isSharingOnActiveBoard {
                    Button {
                        Haptics.warning()
                        withAnimation(.easeOut(duration: 0.24)) {
                            model.disableSharing()
                        }
                    } label: {
                        Text("Stop sharing")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BBTheme.inkMuted)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(BBTheme.hairline.opacity(0.6), lineWidth: 1)
                            }
                    }
                    .buttonStyle(BBPressStyle())
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 22)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BBTheme.hairline.opacity(0.55))
                .frame(height: 1)
        }
        .padding(.horizontal, BBTheme.screenMargin)
    }
}

#Preview {
    CommunityScreen()
}
