//
//  LeapMotionManager.swift
//  LeapDemoSwift
//
//  Created by Kelly Innes on 10/24/15.
//  Copyright © 2015 Kelly Innes. All rights reserved.
//

import Foundation
import Dispatch
import SceneKit

extension UInt32 {
    var boolValue: Bool {
        return (self as NSNumber).boolValue
    }
}

class LeapHandManager: NSObject, ObservableObject {
      
    static let sharedInstance = LeapHandManager()
    private var _rightHandPosition : LEAP_VECTOR? = nil
    private var _leftHandPosition : LEAP_VECTOR? = nil
    private var _rightHand : LEAP_HAND? = nil
    private var _leftHand : LEAP_HAND? = nil
    
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
    
    var rightHandPosition : LEAP_VECTOR?  {
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
    
    let lock = NSLock()

    override init() {
        super.init()
        var config = LEAP_CONNECTION_CONFIG()
        var connection : LEAP_CONNECTION? = OpaquePointer(bitPattern: 0)
        _ = withUnsafeMutablePointer(to: &connection, {
            LeapCreateConnection(&config, $0)
        })
        
        LeapOpenConnection(connection)
        
        let queue = DispatchQueue(label: "leapc", attributes: .concurrent)
        queue.async {
            while true {
                var msg = LEAP_CONNECTION_MESSAGE()
                var result = eLeapRS_Success
                withUnsafeMutablePointer(to: &msg, {
                    result = LeapPollConnection(connection, 100, $0)
                })
                
                if result != eLeapRS_Success {
                    continue
                }
                
                switch msg.type {
                    case eLeapEventType_Tracking:
                        self.onFrame(msg.tracking_event!.pointee)
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
    
    func leftPalmPosAsSCNVector3() -> SCNVector3 {
        var leftPos = SCNVector3()
        if (leftHandPresent() && leftHand != nil && leftHand?.palm.position != nil){
            leftPos = SCNVector3((0.001*(leftHand?.palm.position.x)!), (0.001*(leftHand?.palm.position.y)!), (0.001*(leftHand?.palm.position.z)!))
        }
        return leftPos
    }
    
    func rightPalmPosAsSCNVector3() -> SCNVector3 {
        var rightPos = SCNVector3()
        if (rightHandPresent() && rightHand != nil && rightHand?.palm.position != nil){
            rightPos = SCNVector3((0.001*(rightHand?.palm.position.x)!), (0.001*(rightHand?.palm.position.y)!), (0.001*(rightHand?.palm.position.z)!))
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
        print("Leap Connected")
    }
    
    func onDisconnect(_ connection: _LEAP_CONNECTION_LOST_EVENT){
        print("Disconnected")
    }
    
    func onDevice(_ device: _LEAP_DEVICE_EVENT){
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
    }
}
