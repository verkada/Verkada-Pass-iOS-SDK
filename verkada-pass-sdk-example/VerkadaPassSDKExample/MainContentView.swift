//
//  MainContentView.swift
//  VerkadaPassSDKExampleApp
//
//  Created by Ivan Vavilov on 2025-10-20.
//

import SwiftUI
import VerkadaPassSDK

struct MainContentView: View {
    @EnvironmentObject private var authState: AuthState
    @StateObject var viewModel = MainContentViewModel()

    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.sections) { section in
                    Section {
                        ForEach(section.rows) { row in
                            HStack {
                                Text(row.name)
                                Spacer()
                                Button("Unlock") {
                                    viewModel.unlock(row: row)
                                }
                            }
                        }
                    } header: {
                        Text(section.name)
                    }
                }
            }
            .animation(.easeInOut, value: viewModel.sections)
            .opacity(viewModel.sections.isEmpty ? 0 : 1)

            ProgressView()
                .controlSize(.large)
                .opacity(viewModel.sections.isEmpty ? 1 : 0)
        }
        .alert("Unlocked!", isPresented: $viewModel.showUnlockedDoorAlert) {
            Button("OK", role: .cancel) {
                viewModel.unlockedRow = nil
            }
        } message: {
            if let name = viewModel.unlockedRow?.name {
                Text("\(name) is unlocked")
            } else {
                Text("Door is unlocked")
            }
        }
        .alert("Error", isPresented: $viewModel.showUnlockError) {
            Button("OK", role: .cancel) {
                viewModel.unlockedRow = nil
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .navigationTitle("Doors")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Logout") {
                    viewModel.clearConfiguration()
                    authState.refresh()
                }
            }
        }
        .task {
            await viewModel.fetch()
            viewModel.setup()
        }
    }
}

#Preview {
    NavigationStack {
        MainContentView()
            .environmentObject(AuthState())
    }
}
