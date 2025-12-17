//
//  AuthState.swift
//  VerkadaPassSDKExample
//
//  Created by Ivan Vavilov on 2026-05-19.
//

import Combine
import Foundation
import VerkadaPassSDK

final class AuthState: ObservableObject {
    @Published var isConfigured: Bool

    private var cancellables = Set<AnyCancellable>()

    init() {
        isConfigured = VerkadaPass.shared.isConfigured

        VerkadaPass.shared.logger.log
            .sink { line in
                let prefix: String
                switch line.level {
                case .debug: prefix = "🐞"
                case .info: prefix = "🟢"
                case .error: prefix = "🔴"
                }
                print(prefix + " " + line.message)
            }
            .store(in: &cancellables)
    }

    func refresh() {
        isConfigured = VerkadaPass.shared.isConfigured
    }
}
