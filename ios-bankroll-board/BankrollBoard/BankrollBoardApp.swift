//
//  BankrollBoardApp.swift
//  BankrollBoard
//
//  Created by Rork on September 15, 2026.
//

import SwiftUI
import ClerkKit

@main
struct BankrollBoardApp: App {
    init() {
        AuthConfiguration.configureClerk()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(Clerk.shared)
        }
    }
}
