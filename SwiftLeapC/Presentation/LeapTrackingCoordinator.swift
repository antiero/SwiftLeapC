//
//  LeapTrackingCoordinator.swift
//  Ultraleap Hands
//
//  Created by Antony Nasce on 15/12/2025.

import Foundation

@MainActor
final class LeapTrackingCoordinator {
    static let shared = LeapTrackingCoordinator()

    private var isRunning = false

    func start(enableImages: Bool = true) {
        guard !isRunning else { return }
        isRunning = true
        
        print("Starting LeapTrackingCoordinator")
        LeapSession.shared.start(enableImages: enableImages)
        HandTrackingStore.shared.start(session: .shared)
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        HandTrackingStore.shared.stop()
        LeapSession.shared.stop() // if you have this; otherwise omit
    }
}
