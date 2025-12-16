//
//  HandTrackingStore.swift
//  SwiftLeapC
//

import CoreGraphics
import Combine
import os.lock

@MainActor
final class HandTrackingStore: ObservableObject {
    static let shared = HandTrackingStore()

    // UI-facing state (coalesced)
    @Published private(set) var frame: HandFrame?
    @Published private(set) var status: LeapSession.Status = .idle

    private var frameTask: Task<Void, Never>?
    private var cameraTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?

    // MARK: - Frame snapshot (fast, thread-safe, for render loops)

    nonisolated private let frameSnapshotLock =
        OSAllocatedUnfairLock<HandFrame?>(initialState: nil)

    nonisolated func latestFrameSnapshot() -> HandFrame? {
        frameSnapshotLock.withLock { $0 }
    }

    nonisolated private func setLatestFrameSnapshot(_ f: HandFrame?) {
        frameSnapshotLock.withLock { $0 = f }
    }

    // MARK: - Camera snapshot (fast, thread-safe, pull-based)

    private struct CameraState {
        var seq: Int = 0
        var image: CGImage? = nil
    }

    // MARK: - Camera snapshot (thread-safe, pull-based)

    nonisolated private let cameraSnapshotLock =
        OSAllocatedUnfairLock<(seq: Int, image: CGImage?)>(initialState: (0, nil))

    nonisolated func latestCameraImageSnapshot() -> (seq: Int, image: CGImage?) {
        cameraSnapshotLock.withLock { $0 }
    }


    // MARK: - Lifecycle

    func start(session: LeapSession = .shared) {
        guard frameTask == nil, statusTask == nil else { return }

        // Hand frames: keep snapshot fresh off-main; publish to UI at ~30fps
        frameTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let clock = ContinuousClock()
            let minUIPublishInterval = Duration.milliseconds(33) // ~30fps UI
            var nextUIPublishTime = clock.now

            for await f in session.frames {
                if Task.isCancelled { break }

                self.setLatestFrameSnapshot(f)

                let now = clock.now
                if now >= nextUIPublishTime {
                    nextUIPublishTime = now.advanced(by: minUIPublishInterval)
                    await MainActor.run { [weak self] in self?.frame = f }
                }
            }
        }

        statusTask = Task { [weak self] in
            guard let self else { return }
            for await s in session.status {
                self.status = s
            }
        }
    }

    /// Start/stop camera conversion + snapshotting based on UI need.
    func setCameraPreviewEnabled(_ enabled: Bool, session: LeapSession = .shared) {
        if enabled {
            guard cameraTask == nil else { return }

            let lock = cameraSnapshotLock
            cameraTask = Task.detached(priority: .userInitiated) {
                for await cam in session.cameraFrames {
                    if Task.isCancelled { break }

                    autoreleasepool {
                        let img = cam.makeCGImage()

                        lock.withLock { state in
                            state.seq &+= 1
                            state.image = img
                        }
                    }
                }
            }
        } else {
            cameraTask?.cancel()
            cameraTask = nil

            cameraSnapshotLock.withLock { state in
                state.seq &+= 1
                state.image = nil
            }
        }
    }

    func stop() {
        frameTask?.cancel(); frameTask = nil
        statusTask?.cancel(); statusTask = nil
        cameraTask?.cancel(); cameraTask = nil

        setLatestFrameSnapshot(nil)
        frame = nil

        cameraSnapshotLock.withLock { state in
            state.seq &+= 1
            state.image = nil
        }

        status = .stopped
    }
}
