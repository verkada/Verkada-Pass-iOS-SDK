//
//  LoginViewModel.swift
//  VerkadaPassSDKExample
//
//  Created by Ivan Vavilov on 2026-05-19.
//

import Combine
import Foundation
import SwiftUI
import UIKit
import VerkadaPassSDK

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var challenge: String = ""
    @Published var sdkToken: String = ""
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published private(set) var isLoggingIn: Bool = false

    private let sdk = VerkadaPass.shared

    var canCopyChallenge: Bool { !challenge.isEmpty }
    var canLogin: Bool {
        !challenge.isEmpty && !sdkToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoggingIn
    }

    func generateChallenge() {
        challenge = sdk.generateChallenge()
        sdk.logger.log(.debug, "Code challenge: \(challenge)")
    }

    func copyChallenge() {
        guard !challenge.isEmpty else { return }
        UIPasteboard.general.string = challenge
    }

    func login(onSuccess: @escaping () -> Void) {
        let token = sdkToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !challenge.isEmpty else {
            present(error: "Generate a challenge first.")
            return
        }
        guard !token.isEmpty else {
            present(error: "Paste the SDK token before logging in.")
            return
        }

        isLoggingIn = true
        Task {
            do {
                try await sdk.configure(with: token, clientID: "VerkadaPassSDKExample", shard: shard)
                isLoggingIn = false
                onSuccess()
            } catch let error as APIError {
                isLoggingIn = false
                present(error: error.message)
            } catch let error as HTTPError {
                isLoggingIn = false
                present(error: "HTTP \(error.statusCode)")
            } catch {
                isLoggingIn = false
                present(error: error.localizedDescription)
            }
        }
    }

    private func present(error message: String) {
        errorMessage = message
        showError = true
    }
}
