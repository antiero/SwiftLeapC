//
//  LeapPinchDetector.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 01/07/2023.
//

import Foundation

class LeapPinchDetector : NSObject {
    
    let handManager = LeapHandManager.sharedInstance
    static let sharedInstance = LeapPinchDetector()
    var pinchThreshold : Double = 0.8
    var grabThreshold : Double = 0.8
    var leftPinching : Bool = false
    var rightPinching : Bool = false
    var leftGrabbing : Bool = false
    var rightGrabbing : Bool = false

    private let notificationCenter: NotificationCenter
    static var OnPinchBegan: Notification.Name {
        return .init(rawValue: "PINCH_BEGAN")
    }
    static var OnPinchEnded: Notification.Name {
        return .init(rawValue: "PINCH_ENDED")
    }
    
    static var OnGrabBegan: Notification.Name {
        return .init(rawValue: "GRAB_BEGAN")
    }
    static var OnGrabEnded: Notification.Name {
        return .init(rawValue: "GRAB_ENDED")
    }

    
    override init() {
        notificationCenter = .default
    }
    
    func pinchStrength(hand: LEAP_HAND?) -> Double {
        var pinchAmount = 0.0
        if (hand != nil) {
            pinchAmount = Double(hand!.pinch_strength)
        }
        return pinchAmount
    }
    
    func grabStrength(hand: LEAP_HAND?) -> Double {
        var grabAmount = 0.0
        if (hand != nil) {
            grabAmount = Double(hand!.grab_strength)
        }
        return grabAmount
    }
    
    func updatePinchStates(){
        leftPinching = leftIsPinching()
        rightPinching = rightIsPinching()
    }
    
    func updateGrabStates(){
        leftGrabbing = leftIsPinching()
        rightGrabbing = rightIsPinching()
    }
    
    func leftIsGrabbing() -> Bool {
        let grabStrength = grabStrength(hand: handManager.leftHand)
        if (grabStrength > grabThreshold) {
            if (!leftGrabbing){
                notificationCenter.post(name: LeapPinchDetector.OnGrabBegan, object: handManager.leftHand)
            }
            leftGrabbing = true
        }
        else{
            if (leftGrabbing){
                notificationCenter.post(name: LeapPinchDetector.OnGrabEnded, object: handManager.leftHand)
            }
            leftGrabbing = false
        }
        return leftGrabbing
    }

    
    func leftIsPinching() -> Bool {
        let pinchStrength = pinchStrength(hand: handManager.leftHand)
        if (pinchStrength > pinchThreshold) {
            if (!leftPinching){
                notificationCenter.post(name: LeapPinchDetector.OnPinchBegan, object: handManager.leftHand)
            }
            leftPinching = true
        }
        else{
            if (leftPinching){
                notificationCenter.post(name: LeapPinchDetector.OnPinchEnded, object: handManager.leftHand)
            }
            leftPinching = false
        }
        return leftPinching
    }
    
    func rightIsGrabbing() -> Bool {
        let grabStrength = grabStrength(hand: handManager.rightHand)
        if (grabStrength > grabThreshold) {
            if (!rightGrabbing){
                notificationCenter.post(name: LeapPinchDetector.OnGrabBegan, object: handManager.rightHand)
            }
            rightGrabbing = true
        }
        else{
            if (rightGrabbing){
                notificationCenter.post(name: LeapPinchDetector.OnGrabEnded, object: handManager.rightHand)
            }
            rightGrabbing = false
        }
        return leftGrabbing
    }
    
    func rightIsPinching() -> Bool {
        let pinchStrength = pinchStrength(hand: handManager.rightHand)
        if (pinchStrength > pinchThreshold) {
            if (!rightPinching){
                notificationCenter.post(name: LeapPinchDetector.OnPinchBegan, object: handManager.rightHand)
            }
            rightPinching = true
        }
        else {
            if (rightPinching){
                notificationCenter.post(name: LeapPinchDetector.OnPinchEnded, object: handManager.rightHand)
            }
            rightPinching = false
        }
        return rightPinching
    }
}
