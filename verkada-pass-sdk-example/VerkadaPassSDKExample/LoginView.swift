//
//  LoginView.swift
//  VerkadaPassSDKExample
//
//  Created by Ivan Vavilov on 2026-05-19.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authState: AuthState
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        Form {
            Section("Challenge") {
                TextField("Challenge", text: .constant(viewModel.challenge))
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                    .foregroundStyle(.primary)

                Button("Copy") {
                    viewModel.copyChallenge()
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canCopyChallenge)
            }

            Section("SDK Token") {
                TextField("Paste the SDK token here", text: $viewModel.sdkToken, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
            }

            Section {
                Button {
                    viewModel.login {
                        authState.refresh()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoggingIn {
                            ProgressView()
                        } else {
                            Text("Login")
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canLogin)
            }
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.challenge.isEmpty {
                viewModel.generateChallenge()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthState())
    }
}
