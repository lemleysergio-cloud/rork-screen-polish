//
//  JourneyTabBar.swift
//  BankrollBoard
//

import SwiftUI

/// Bottom navigation destinations.
nonisolated enum BBTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case stats
    case journey
    case community
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .stats: "Stats"
        case .journey: "Journey"
        case .community: "Community"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .stats: "chart.bar.fill"
        case .journey: "paperplane.fill"
        case .community: "person.2.fill"
        case .settings: "gearshape"
        }
    }
}

/// Floating pill tab bar with a gold lozenge behind the active item.
struct BBTabBar: View {
    @Binding var selection: BBTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BBTab.allCases) { tab in
                let isActive = tab == selection
                Button(action: {
                    guard tab != selection else { return }
                    Haptics.selection()
                    selection = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 17, weight: isActive ? .semibold : .regular))
                        Text(tab.title)
                            .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(isActive ? BBTheme.gold : BBTheme.inkMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        if isActive {
                            Capsule()
                                .fill(BBTheme.gold.opacity(0.13))
                                .overlay {
                                    Capsule().stroke(BBTheme.gold.opacity(0.32), lineWidth: 1)
                                }
                                .padding(.horizontal, 4)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(BBPressStyle())
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isActive ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 6)
        .background {
            Capsule()
                .fill(BBTheme.canvasDeep.opacity(0.92))
                .overlay {
                    Capsule().stroke(BBTheme.hairline.opacity(0.65), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
        }
        .padding(.horizontal, 14)
        .animation(.spring(response: 0.34, dampingFraction: 0.8), value: selection)
    }
}
