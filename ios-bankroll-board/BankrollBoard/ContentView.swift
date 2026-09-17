//
//  ContentView.swift
//  BankrollBoard
//

import SwiftUI

struct ContentView: View {
    /// Onboarding runs once, then the app lands on the Journey map.
    @State private var hasFinishedOnboarding: Bool = true

    var body: some View {
        if hasFinishedOnboarding {
            JourneyHeroScreen()
        } else {
            OnboardingFlowView()
        }
    }
}

#Preview {
    ContentView()
}
