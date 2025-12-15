//
//  LeapSession.swift
//  SwiftLeapC
//
//  Owns the LeapC connection + polling loop and exposes typed async streams.
//

import Foundation

public final class LeapSession {
    
    enum Status: Sendable, Equatable, CustomStringConvertible {
        case idle
        case starting
        case running
        case stopped
        case connectionLost
        case error(String)
        
        var description: String {
            switch self {
            case .idle: return "Idle"
            case .starting: return "Starting…"
            case .running: return "Running"
            case .stopped: return "Stopped"
            case .connectionLost: return "Connection lost"
            case .error(let msg): return "Error: \(msg)"
            }
        }
    }
    
    public static let shared = LeapSession()
    
    // Async streams (internal for app use; avoid access-control headaches)
    lazy var frames: AsyncStream<HandFrame> = AsyncStream { [weak self] cont in
        self?.framesContinuation = cont
        cont.onTermination = { [weak self] _ in self?.framesContinuation = nil }
    }
    
    lazy var cameraFrames: AsyncStream<CameraFrame> = AsyncStream { [weak self] cont in
        self?.cameraContinuation = cont
        cont.onTermination = { [weak self] _ in self?.cameraContinuation = nil }
    }
    
    lazy var status: AsyncStream<Status> = AsyncStream { [weak self] cont in
        self?.statusContinuation = cont
        cont.onTermination = { [weak self] _ in self?.statusContinuation = nil }
    }
    
    private var framesContinuation: AsyncStream<HandFrame>.Continuation?
    private var cameraContinuation: AsyncStream<CameraFrame>.Continuation?
    private var statusContinuation: AsyncStream<Status>.Continuation?
    
    private var pollTask: Task<Void, Never>?
    
    private var connection: LEAP_CONNECTION? = nil
    
    // Snapshots for consumers that need synchronous access (e.g. SceneKit render loop).
    private let snapshotLock = NSLock()
    private var _latestFrame: HandFrame?
    
    private let debugEnabled = UserDefaults.standard.bool(forKey: "LeapDebug")
    private func dbg(_ msg: @autoclosure () -> String) {
        guard debugEnabled else { return }
        print("[LeapSession] \(msg())")
    }
    
    private var _latestCamera: CameraFrame?
    
    public func latestFrameSnapshot() -> HandFrame? {
        snapshotLock.lock(); defer { snapshotLock.unlock() }
        return _latestFrame
    }
    
    public func latestCameraSnapshot() -> CameraFrame? {
        snapshotLock.lock(); defer { snapshotLock.unlock() }
        return _latestCamera
    }
    
    private init() {
        // Streams are lazy; this keeps init simple and avoids continuation lifetime bugs.
    }
    
    deinit {
        stop()
    }
    
    public func start(enableImages: Bool = true) {
        guard pollTask == nil else { return }
        
        // Create + open connection
        var config = LEAP_CONNECTION_CONFIG()
        var conn: LEAP_CONNECTION? = OpaquePointer(bitPattern: 0)
        _ = withUnsafeMutablePointer(to: &conn) { LeapCreateConnection(&config, $0) }
        connection = conn
        dbg("start(): created connection \(String(describing: conn))")
        
        if enableImages, let conn {
            // Prefer the named enum constant, but LeapC imports can be finicky across Swift versions.
            // eLeapPolicyFlag_Images == 0x00000002
            LeapSetPolicyFlags(conn, UInt64(eLeapPolicyFlag_Images.rawValue), 0)
        }
        
        if let conn {
            LeapOpenConnection(conn)
            dbg("start(): opened connection")
        }
        
        statusContinuation?.yield(.running)
        
        pollTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            self.pollLoop()
        }
    }
    
    public func stop() {
        dbg("stop(): cancelling poll task")
        pollTask?.cancel()
        pollTask = nil
        
        if let conn = connection {
            LeapCloseConnection(conn)
            LeapDestroyConnection(conn)
        }
        connection = nil
        
        statusContinuation?.yield(.stopped)
    }
    
    private func pollLoop() {
        guard let conn = connection else { return }
        
        while !Task.isCancelled {
            autoreleasepool {
                var msg = LEAP_CONNECTION_MESSAGE()
                var result = eLeapRS_Success
                withUnsafeMutablePointer(to: &msg) {
                    result = LeapPollConnection(conn, 100, $0)
                }
                
                if result != eLeapRS_Success {
                    dbg("pollLoop(): LeapPollConnection failed with code \(result.rawValue)")
                    statusContinuation?.yield(.connectionLost)
                    return
                }
                
                switch msg.type {
                case eLeapEventType_Tracking:
                    // Debug: enable by setting UserDefaults key 'LeapDebug' = true
                    dbg("event: Tracking")
                    let frame = LeapEventMapper.mapTrackingEvent(msg.tracking_event!.pointee)
                    snapshotLock.lock()
                    _latestFrame = frame
                    snapshotLock.unlock()
                    framesContinuation?.yield(frame)
                    
                case eLeapEventType_Image:
                    dbg("event: Image")
                    if let cam = LeapEventMapper.mapImageEvent(msg.image_event!.pointee) {
                        snapshotLock.lock()
                        _latestCamera = cam
                        snapshotLock.unlock()
                        cameraContinuation?.yield(cam)
                    }
                    
                case eLeapEventType_ConnectionLost:
                    statusContinuation?.yield(.connectionLost)
                    
                default:
                    break
                }
            }
        }
    }
}
