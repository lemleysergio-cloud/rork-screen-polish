//
//  RootShellView.swift
//  BankrollBoard
//
//  Owns the bottom tab bar and routes every tab to a real destination.
//

import SwiftUI

struct RootShellView: View {
    @State private var selectedTab: BBTab = .journey

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeScreen()
                case .stats:
                    StatsScreen()
                case .journey:
                    JourneyHeroScreen()
                case .community:
                    CommunityScreen()
                case .settings:
                    BBPlaceholderScreen(
                        eyebrow: "SETTINGS",
                        title: "Settings",
                        message: "Account, privacy controls, moderation tools, and responsible-gaming limits."
                    )
                }
            }
            .transition(.opacity)

            BBTabBar(selection: $selectedTab)
                .padding(.bottom, 6)
        }
        .animation(.easeOut(duration: 0.18), value: selectedTab)
        .preferredColorScheme(.dark)
    }
}

/// Branded stand-in for tabs that are not built yet.
struct BBPlaceholderScreen: View {
    let eyebrow: String
    let title: String
    let message: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [JourneyPalette.canvasDeep, JourneyPalette.canvas, Color(rgb: 0x132F20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .black))
                    .kerning(1.4)
                    .foregroundStyle(JourneyPalette.gold)

                Text(title)
                    .font(.system(size: 40, weight: .regular, design: .serif))
                    .foregroundStyle(JourneyPalette.ink)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(BBTheme.inkMuted)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Text("In progress")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(JourneyPalette.gold)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background {
                        Capsule().stroke(JourneyPalette.gold.opacity(0.35), lineWidth: 1)
                    }
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, BBTheme.screenMargin)
        }
    }
}

#Preview {
    RootShellView()
}
