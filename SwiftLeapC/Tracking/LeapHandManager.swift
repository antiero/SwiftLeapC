//
//  LeapHandManager.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 01/07/2023.
//

import Foundation
import Dispatch
import SceneKit

extension UInt32 {
    var boolValue: Bool {
        return (self as NSNumber).boolValue
    }
}

class LeapHandManager: NSObject {
      
    static let sharedInstance = LeapHandManager()
    private var _rightHandPosition : LEAP_VECTOR? = nil
    private var _leftHandPosition : LEAP_VECTOR? = nil
    private var _rightHand : LEAP_HAND? = nil
    private var _leftHand : LEAP_HAND? = nil
    public private(set) var currentImage: CGImage?
    private let imageLock = NSLock()
    private var imageBuffers: [Data] = [Data(), Data()]
    private var activeImageBufferIndex: Int = 0
    private var lastImageSize: Int = 0
    
    var currentFrameID: Int64
    private let notificationCenter: NotificationCenter
    static var OnNewLeapFrame: Notification.Name {
        return .init(rawValue: "NEW_LEAP_FRAME")
    }
    static var OnDisconnect: Notification.Name {
        return .init(rawValue: "DISCONNECT")
    }
    
    private let lock = NSLock()
    
    var leftHand : LEAP_HAND? {
        get {
            lock.lock()
            let tmp = _leftHand
            lock.unlock()
            return tmp
        }
        set {
            lock.lock()
            _leftHand = newValue
            lock.unlock()
        }
    }
    
    var rightHand : LEAP_HAND? {
        get {
            lock.lock()
            let tmp = _rightHand
            lock.unlock()
            return tmp
        }
        set {
            lock.lock()
            _rightHand = newValue
            lock.unlock()
        }
    }
    
    var rightHandPosition : LEAP_VECTOR? {
        get {
            lock.lock()
            let tmp = _rightHandPosition
            lock.unlock()
            return tmp
        }
        set {
            lock.lock()
            _rightHandPosition = newValue
            lock.unlock()
        }
    }
    var leftHandPosition : LEAP_VECTOR? {
        get {
            lock.lock()
            let tmp = _leftHandPosition
            lock.unlock()
            return tmp
        }
        set {
            lock.lock()
            _leftHandPosition = newValue
            lock.unlock()
        }
    }
    
    override init() {
        currentFrameID = 0
        notificationCenter = .default
        super.init()
        var config = LEAP_CONNECTION_CONFIG()
        var connection : LEAP_CONNECTION? = OpaquePointer(bitPattern: 0)
        _ = withUnsafeMutablePointer(to: &connection, {
            LeapCreateConnection(&config, $0)
        })
        //LeapSetPolicyFlags(connection, eLeapPolicyFlag_Images, 0);
        LeapSetPolicyFlags(connection, 0x00000002, 0)
        LeapOpenConnection(connection)
        
        let queue = DispatchQueue(label: "leapc", attributes: .concurrent)
        queue.async { [weak self] in
            guard let self = self else { return }
            while true {
                autoreleasepool {
                    var msg = LEAP_CONNECTION_MESSAGE()
                    var result = eLeapRS_Success
                    withUnsafeMutablePointer(to: &msg, {
                        result = LeapPollConnection(connection, 100, $0)
                    })
                    
                    // If polling fails, exit this worker
                    if result != eLeapRS_Success {
                        //print("LeapPollConnection failed with code \(result.rawValue)")
                        return
                    }
                    
                    switch msg.type {
                    case eLeapEventType_Tracking:
                        self.onFrame(msg.tracking_event!.pointee)
                    case eLeapEventType_Image:
                        self.onImage(msg.image_event!.pointee)
                    case eLeapEventType_Connection:
                        self.onConnect(msg.connection_event!.pointee)
                    case eLeapEventType_ConnectionLost:
                        self.onDisconnect(msg.connection_lost_event!.pointee)
                    case eLeapEventType_Device:
                        self.onDevice(msg.device_event!.pointee)
                    case eLeapEventType_DeviceLost:
                        self.onDeviceLost(msg.device_event!.pointee)
                    default: break
                    }
                }
            }
        }
    }
    
    
    func leftPalmPosAsSCNVector3() -> SCNVector3 {
        var leftPos = SCNVector3()
        if let palmPosition = leftHand?.palm.position{
            leftPos = SCNVector3((0.001*(palmPosition.x)), (0.001*(palmPosition.y)), (0.001*(palmPosition.z)))
        }
        return leftPos
    }
    
    func rightPalmPosAsSCNVector3() -> SCNVector3 {
        var rightPos = SCNVector3()
        if let palmPosition = rightHand?.palm.position{
            rightPos = SCNVector3((0.001*(palmPosition.x)), (0.001*(palmPosition.y)), (0.001*(palmPosition.z)))
        }
        return rightPos
    }
    
    func leftHandPresent() -> Bool {
        return (leftHand != nil)
    }
    
    func rightHandPresent() -> Bool {
        return (rightHand != nil)
    }
    
    func onConnect(_ connection: _LEAP_CONNECTION_EVENT){
        print("Leap Connected", connection)
    }
    
    func onDisconnect(_ connection: _LEAP_CONNECTION_LOST_EVENT){
        print("Disconnected")
        notificationCenter.post(name: LeapHandManager.OnDisconnect, object: connection)
    }
    
    func onDevice(_ device: _LEAP_DEVICE_EVENT){
        // LEAP_DEVICE_REF has .handle and .id (see LeapC.h), not .serial
        print("On Device Change with ID:", device.device.id)
    }
    
    func onDeviceLost(_ device: _LEAP_DEVICE_EVENT){
        print("On Device Lost:", device.device.id)
    }
    
    func onFrame(_ frame: LEAP_TRACKING_EVENT) {
        leftHandPosition = nil
        rightHandPosition = nil
        leftHand = nil
        rightHand = nil
        currentFrameID = frame.tracking_frame_id
        
        for i in 0 ..< frame.nHands {
            let hand = frame.pHands.advanced(by: Int(i)).pointee
            if hand.type == eLeapHandType_Left {
                leftHand = hand
                leftHandPosition = leftHand!.palm.position
            } else {
                rightHand = hand
                rightHandPosition = rightHand!.palm.position
            }
        }
        notificationCenter.post(name: LeapHandManager.OnNewLeapFrame, object: currentFrameID)
    }
    
    
    func onImage(_ imageEvent: _LEAP_IMAGE_EVENT) {
        let leftImage = imageEvent.image.0
        guard let srcPtr = leftImage.data else { return }
        
        let props = leftImage.properties
        let width = Int(props.width)
        let height = Int(props.height)
        let byteCount = width * height
        guard byteCount > 0 else { return }
        
        // Ensure buffers are sized once (or when resolution changes)
        if byteCount != lastImageSize {
            imageBuffers[0] = Data(count: byteCount)
            imageBuffers[1] = Data(count: byteCount)
            lastImageSize = byteCount
        }
        
        // Write into the "back" buffer
        let backIndex = (activeImageBufferIndex + 1) & 1
        imageBuffers[backIndex].withUnsafeMutableBytes { dst in
            guard let dstBase = dst.baseAddress else { return }
            memcpy(dstBase, srcPtr, byteCount)
        }
        
        // Build CGImage backed by OUR Data (not Leap's)
        let cfData = imageBuffers[backIndex] as CFData
        guard let provider = CGDataProvider(data: cfData) else { return }
        
        let img = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
        
        // Swap atomically under lock so renderer/UI never sees half-updates
        imageLock.lock()
        currentImage = img
        activeImageBufferIndex = backIndex
        imageLock.unlock()
    }
    
    func getCurrentImageThreadSafe() -> CGImage? {
        imageLock.lock()
        let img = currentImage
        imageLock.unlock()
        return img
    }
}
