//
//  VerkadaPassSDKExampleApp.swift
//  VerkadaPassSDKExample
//
//  Created by Ivan Vavilov on 2025-10-20.
//

import SwiftUI
import VerkadaPassSDK

// Shard the example app talks to. Override here to point at a different region.
let shard: Shard = .us

@main
struct VerkadaPassSDKExampleApp: App {
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if authState.isConfigured {
                    MainContentView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(authState)
            .onAppear {
                let navigationBarAppearance = UINavigationBarAppearance()
                navigationBarAppearance.configureWithDefaultBackground()
                navigationBarAppearance.backgroundColor = .white
                let appearance = UINavigationBar.appearance()
                appearance.standardAppearance = navigationBarAppearance
                appearance.scrollEdgeAppearance = navigationBarAppearance
            }
        }
    }
}
