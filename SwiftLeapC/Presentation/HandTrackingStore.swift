//
//  HandTrackingStore.swift
//  SwiftLeapC
//
//  UI-facing state for AppKit/SwiftUI.
//  Copyright © 2025 Antony Nasce. All rights reserved.

import CoreGraphics
import Combine
import os.lock

@MainActor
final class HandTrackingStore: ObservableObject {
    static let shared = HandTrackingStore()

    @Published private(set) var frame: HandFrame?
    @Published private(set) var cameraImage: CGImage?
    @Published private(set) var status: LeapSession.Status = .idle
    
    private var frameTask: Task<Void, Never>?
    private var cameraTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?
    
    // Thread-safe snapshot for render loops that may run off-main.
    nonisolated private let frameSnapshotLock = OSAllocatedUnfairLock<HandFrame?>(initialState: nil)
    
    nonisolated func latestFrameSnapshot() -> HandFrame? {
        frameSnapshotLock.withLock { $0 }
    }
    
    private func publishFrame(_ f: HandFrame?) {
        self.frame = f
        frameSnapshotLock.withLock { $0 = f }
    }
    
    func start(session: LeapSession = .shared) {
        guard frameTask == nil, cameraTask == nil, statusTask == nil else { return }

        frameTask = Task { [weak self] in
            guard let self else { return }
            for await f in session.frames {
                self.publishFrame(f)  // was: self.frame = f
            }
        }

        cameraTask = Task { [weak self] in
            guard let self else { return }
            for await cam in session.cameraFrames {
                if Task.isCancelled { break }

                // Convert off the MainActor to keep UI responsive (especially at higher camera frame rates).
                let cgImage: CGImage? = await withCheckedContinuation { continuation in
                    DispatchQueue.global(qos: .userInitiated).async {
                        let img = cam.makeCGImage()
                        continuation.resume(returning: img)
                    }
                }

                self.cameraImage = cgImage
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
        
        publishFrame(nil) // clear both published + snapshot
        status = .stopped
    }
}
