//
//  MainContentViewModel.swift
//  VerkadaPassSDKExampleApp
//
//  Created by Ivan Vavilov on 2025-12-01.
//

import Combine
import Foundation
import SwiftUI
import VerkadaPassSDK

final class MainContentViewModel: ObservableObject {
    @Published private(set) var sections = [DoorSection]()
    @Published var errorMessage = ""
    @Published var showUnlockError = false
    @Published var unlockedRow: DoorRow?
    @Published var showUnlockedDoorAlert = false

    private var nearbyDevicesSection = DoorSection(name: "Nearby Devices", building: nil, floor: nil, rows: [])
    private var cancellable = Set<AnyCancellable>()
    private let sdk = VerkadaPass.shared
    private lazy var bleService = sdk.bluetoothService
    private lazy var locationService = sdk.locationService
    private lazy var logger = sdk.logger

    deinit {
        cancellable.forEach { $0.cancel() }
        cancellable.removeAll()
    }

    func fetch() async {
        do {
            sections = try await sdk.fetchDevices()
        } catch {
            logError(error)
        }
    }

    func setup() {
        guard cancellable.isEmpty else { return }

        bleService.askPermission()
        locationService.askPermission()

        locationService.startLocating()
        locationService.startMonitoring()
        bleService.start()

        bleService.connectedEntities.combineLatest(locationService.nearbyEntities)
            .map { $0 + $1 }
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { entities in
                let newRows = entities.compactMap { entity in
                    if let door = entity as? Door {
                        return DoorRow(door, adapter: nil, baseImageURL: nil, isNearby: true)
                    } else if let elevator = entity as? Elevator {
                        return DoorRow(elevator, isNearby: true)
                    }
                    return nil
                }
                self.nearbyDevicesSection.rows = newRows

                withAnimation {
                    if !entities.isEmpty, self.sections.first?.id != self.nearbyDevicesSection.id {
                        self.sections.insert(self.nearbyDevicesSection, at: 0)
                    } else if !entities.isEmpty {
                        self.sections[0] = self.nearbyDevicesSection
                    } else if self.sections.first?.name == self.nearbyDevicesSection.id {
                        self.sections.removeFirst()
                    }
                }
            }
            .store(in: &cancellable)
    }

    func unlock(row: DoorRow) {
        Task {
            do {
                try await sdk.unlock(row)
                unlockedRow = row
                showUnlockedDoorAlert = true
            } catch let error as APIError {
                errorMessage = error.message
                showUnlockError = true
            } catch let error as UnlockError {
                errorMessage = error.message
                showUnlockError = true
            } catch {
                errorMessage = error.localizedDescription
                showUnlockError = true
            }
        }
    }

    func clearConfiguration() {
        sdk.clearConfiguration()
        cancellable.forEach { $0.cancel() }
        cancellable.removeAll()
        sections = []
    }

    private func logError(_ error: Error) {
        let errorText = switch error {
        case let error as APIError:
            error.message
        case let error as HTTPError:
            "HTTP \(error.statusCode)"
        default:
            error.localizedDescription
        }
        logger.log(.error, errorText)
    }
}
