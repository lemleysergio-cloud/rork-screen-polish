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
    @State private var accounts = AccountStore()
    @State private var showsQuickSignInOffer: Bool = false
    /// After logging out, don't pop Face ID straight back up.
    @State private var didSignOutThisLaunch: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    /// UI tests pass `-skipAuth` to launch straight into the app.
    private let skipsAuth: Bool = ProcessInfo.processInfo.arguments.contains("-skipAuth")

    var body: some View {
        ZStack {
            if !isSignedIn && !skipsAuth {
                AuthScreen(autoPromptsQuickSignIn: !didSignOutThisLaunch) { session in
                    signIn(session)
                }
                .transition(.opacity)
            } else if hasFinishedOnboarding {
                RootShellView {
                    signOut()
                }
                .transition(.opacity)
            } else {
                OnboardingFlowView()
                    .transition(.opacity)
            }
        }
        .environment(accounts)
        .sheet(isPresented: $showsQuickSignInOffer) {
            QuickSignInOfferView()
                .environment(accounts)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { accounts.refreshBiometrics() }
        }
    }

    private func signIn(_ session: AuthSession) {
        accounts.didSignIn(session)
        withAnimation(.easeInOut(duration: 0.4)) {
            isSignedIn = true
        }
        guard accounts.shouldOfferQuickSignIn else { return }
        Task {
            // Let the board fade in before inviting Face ID.
            try? await Task.sleep(for: .milliseconds(700))
            showsQuickSignInOffer = true
        }
    }

    private func signOut() {
        accounts.signOut()
        didSignOutThisLaunch = true
        withAnimation(.easeInOut(duration: 0.4)) {
            isSignedIn = false
        }
    }
}

#Preview {
    ContentView()
}
