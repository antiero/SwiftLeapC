//
//  HandTrackingStore.swift
//  SwiftLeapC
//
//  UI-facing state for AppKit/SwiftUI.
//

import CoreGraphics
import Combine

@MainActor
final class HandTrackingStore: ObservableObject {
    static let shared = HandTrackingStore()

    @Published private(set) var frame: HandFrame?
    @Published private(set) var cameraImage: CGImage?
    @Published private(set) var status: LeapSession.Status = .idle

    /// SwiftUI-friendly derived text (NOT published; observe `status` instead)
    var statusText: String { status.description }

    private var frameTask: Task<Void, Never>?
    private var cameraTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?

    private init() {}

    func start(session: LeapSession = .shared) {
        guard frameTask == nil, cameraTask == nil, statusTask == nil else { return }

        frameTask = Task { [weak self] in
            guard let self else { return }
            for await f in session.frames {
                self.frame = f
            }
        }

        cameraTask = Task { [weak self] in
            guard let self else { return }
            for await cam in session.cameraFrames {
                self.cameraImage = cam.makeCGImage()
            }
        }

        statusTask = Task { [weak self] in
            guard let self else { return }
            for await s in session.status {
                self.status = s
            }
        }
    }

    func stop() {
        frameTask?.cancel(); frameTask = nil
        cameraTask?.cancel(); cameraTask = nil
        statusTask?.cancel(); statusTask = nil
        status = .stopped
    }
}
