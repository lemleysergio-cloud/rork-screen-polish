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
    @State private var accounts: AccountStore
    @State private var showsQuickSignInOffer: Bool = false
    /// After logging out, don't pop Face ID straight back up.
    @State private var didSignOutThisLaunch: Bool = false
    @State private var isCheckingSession: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    private let authService: any AuthService

    /// UI tests pass `-skipAuth` to launch straight into the app.
    private let skipsAuth: Bool = ProcessInfo.processInfo.arguments.contains("-skipAuth")

    init(authService: any AuthService = ClerkAuthService()) {
        self.authService = authService
        _accounts = State(initialValue: AccountStore(service: authService))
    }

    var body: some View {
        ZStack {
            if isCheckingSession && !skipsAuth {
                ProgressView("Checking your session…")
                    .tint(AuthPalette.forest)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background { AuthBackground() }
            } else if !isSignedIn && !skipsAuth {
                AuthScreen(
                    autoPromptsQuickSignIn: !didSignOutThisLaunch,
                    service: authService
                ) { session in
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
        .task {
            guard !skipsAuth else {
                isCheckingSession = false
                return
            }
            if let session = await authService.currentSession() {
                signIn(session, offersQuickSignIn: false)
            } else {
                isSignedIn = false
            }
            isCheckingSession = false
        }
    }

    private func signIn(_ session: AuthSession, offersQuickSignIn: Bool = true) {
        accounts.didSignIn(session)
        withAnimation(.easeInOut(duration: 0.4)) {
            isSignedIn = true
        }
        guard offersQuickSignIn, accounts.shouldOfferQuickSignIn else { return }
        Task {
            // Let the board fade in before inviting Face ID.
            try? await Task.sleep(for: .milliseconds(700))
            showsQuickSignInOffer = true
        }
    }

    private func signOut() {
        Task {
            try? await authService.signOut()
            accounts.signOut()
            didSignOutThisLaunch = true
            withAnimation(.easeInOut(duration: 0.4)) {
                isSignedIn = false
            }
        }
    }
}

#Preview {
    ContentView(authService: DemoAuthService())
}
