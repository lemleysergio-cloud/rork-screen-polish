//
//  ContentView.swift
//  BankrollBoard
//

import SwiftUI

struct ContentView: View {
    /// Remembers a completed sign-in so the login screen only shows when signed out.
    @AppStorage("bb.isSignedIn") private var isSignedIn: Bool = false
    /// Onboarding runs once, then the app lands on the Journey map.
    @State private var hasFinishedOnboarding: Bool = true

    /// UI tests pass `-skipAuth` to launch straight into the app.
    private let skipsAuth: Bool = ProcessInfo.processInfo.arguments.contains("-skipAuth")

    var body: some View {
        ZStack {
            if !isSignedIn && !skipsAuth {
                AuthScreen { _ in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isSignedIn = true
                    }
                }
                .transition(.opacity)
            } else if hasFinishedOnboarding {
                RootShellView()
                    .transition(.opacity)
            } else {
                OnboardingFlowView()
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
}
