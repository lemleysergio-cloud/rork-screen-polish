//
//  HomeSyncViews.swift
//  BankrollBoard
//
//  Refresh affordances for Home: the sync bar, the result banner, and the
//  reconnect prompt shown when a bank connection breaks.
//

import SwiftUI

// MARK: - Sync bar

/// Last-synced caption plus a manual refresh control.
///
/// Sits above the hero so the freshness of every number below it is stated
/// before the user reads them.
struct HomeSyncBar: View {
    let caption: String
    let isSyncing: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HomeSyncSpinner(isActive: isSyncing)

            Text(isSyncing ? "Syncing with your bank…" : "Updated \(caption.lowercased())")
                .font(.system(size: 11))
                .foregroundStyle(BBTheme.inkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .contentTransition(.opacity)

            Spacer(minLength: 8)

            Button(action: onRefresh) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Refresh")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(isSyncing ? BBTheme.inkMuted : BBTheme.gold)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background {
                    Capsule()
                        .stroke(
                            (isSyncing ? BBTheme.hairline : BBTheme.gold.opacity(0.35)),
                            lineWidth: 1
                        )
                }
                .contentShape(Capsule())
                .frame(height: 44)
            }
            .buttonStyle(BBPressStyle())
            .disabled(isSyncing)
            .accessibilityLabel("Refresh transactions")
            .accessibilityHint(isSyncing ? "Sync already in progress" : "Pulls the latest transfers from your bank")
        }
        .animation(.easeInOut(duration: 0.22), value: isSyncing)
    }
}

/// Gold arc that spins only while a sync is running.
struct HomeSyncSpinner: View {
    let isActive: Bool

    @State private var angle: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(BBTheme.hairline.opacity(0.8), lineWidth: 1.6)

            if isActive {
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        BBTheme.gold,
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(angle))
            } else {
                Circle()
                    .fill(BBTheme.positive.opacity(0.65))
                    .frame(width: 5, height: 5)
            }
        }
        .frame(width: 14, height: 14)
        .onChange(of: isActive) { _, active in
            if active { startSpin() }
        }
        .onAppear {
            if isActive { startSpin() }
        }
        .accessibilityHidden(true)
    }

    private func startSpin() {
        angle = 0
        withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
            angle = 360
        }
    }
}

// MARK: - Result banner

/// Reports the outcome of a refresh: what changed, or why it failed.
struct HomeSyncBanner: View {
    let phase: HomeSyncPhase
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        switch phase {
        case .idle, .syncing:
            EmptyView()
        case .succeeded(let newTransfers, let newlySettled):
            banner(
                symbol: "checkmark.circle.fill",
                tint: BBTheme.positive,
                message: successMessage(newTransfers: newTransfers, newlySettled: newlySettled),
                actionTitle: nil
            )
        case .failed(let message, let isRecoverable):
            banner(
                symbol: "exclamationmark.triangle.fill",
                tint: Color(rgb: 0xE2928A),
                message: message,
                actionTitle: isRecoverable ? "Retry" : nil
            )
        }
    }

    private func successMessage(newTransfers: Int, newlySettled: Int) -> String {
        var parts: [String] = []
        if newTransfers > 0 {
            parts.append("\(newTransfers) new transfer\(newTransfers == 1 ? "" : "s")")
        }
        if newlySettled > 0 {
            parts.append("\(newlySettled) now settled")
        }
        guard !parts.isEmpty else { return "You're up to date." }
        return parts.joined(separator: " · ")
    }

    private func banner(
        symbol: String,
        tint: Color,
        message: String,
        actionTitle: String?
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(tint)

            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(BBTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            if let actionTitle {
                Button(action: onRetry) {
                    Text(actionTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BBTheme.gold)
                        .frame(height: 44)
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BBPressStyle())
            } else {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(BBTheme.inkMuted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BBPressStyle())
                .accessibilityLabel("Dismiss")
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 2)
        .padding(.vertical, 2)
        .background {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(tint.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(tint.opacity(0.28), lineWidth: 1)
                }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Reconnect prompt

/// Shown when Plaid reports an item needs the user to sign in again.
/// Until they do, the balance below it is stale and says so.
struct HomeReconnectCard: View {
    let accounts: [LinkedAccount]
    let onReconnect: (LinkedAccount) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(rgb: 0xE2A25A))
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 3) {
                    Text(accounts.count == 1 ? "A bank connection needs attention" : "\(accounts.count) bank connections need attention")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(BBTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("New transfers won't appear until you reconnect.")
                        .font(.system(size: 11))
                        .foregroundStyle(BBTheme.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            ForEach(accounts) { account in
                HStack(spacing: 10) {
                    Image(systemName: account.connection.symbol)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(rgb: 0xE2A25A))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BBTheme.ink)
                        Text("Last synced \(homeRelativeTime(account.lastSyncedAt).lowercased())")
                            .font(.system(size: 10))
                            .foregroundStyle(BBTheme.inkMuted)
                    }

                    Spacer(minLength: 8)

                    if account.connection.requiresUserAction {
                        Button {
                            onReconnect(account)
                        } label: {
                            Text("Reconnect")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(JourneyPalette.canvasDeep)
                                .padding(.horizontal, 14)
                                .frame(height: 34)
                                .background { Capsule().fill(BBTheme.gold) }
                                .contentShape(Capsule())
                        }
                        .buttonStyle(BBPressStyle())
                        .accessibilityLabel("Reconnect \(account.institutionName)")
                    } else {
                        Text(account.connection.label)
                            .font(.system(size: 11))
                            .foregroundStyle(BBTheme.inkMuted)
                    }
                }
            }
        }
        .padding(15)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(rgb: 0xE2A25A).opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(rgb: 0xE2A25A).opacity(0.3), lineWidth: 1)
                }
        }
    }
}
