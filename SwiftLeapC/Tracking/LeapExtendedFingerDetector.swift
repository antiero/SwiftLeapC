//
//  LeapExtendedFingerDetector.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 01/07/2023.
//

import Foundation

class LeapExtendedFingerDetector : ObservableObject {
    
    let handManager = LeapHandManager.sharedInstance
    static let sharedInstance = LeapExtendedFingerDetector()
    @Published var leftPinching : Bool = false
    @Published var rightPinching : Bool = false

    func isFingerExtended(finger: LEAP_DIGIT) -> Bool {
        return finger.is_extended.boolValue
    }
    
    func isHandPointing(hand: LEAP_HAND) -> Bool {
        let test = (hand.index.is_extended.boolValue &&
            !hand.middle.is_extended.boolValue &&
            !hand.ring.is_extended.boolValue &&
            !hand.pinky.is_extended.boolValue)
        
        return test
    }
    
    func isLeftHandPointing() -> Bool {
        var pointing = false
        if (handManager.leftHandPresent() && handManager.leftHand != nil){
            if let hand = handManager.leftHand {
                pointing = isHandPointing(hand: hand)
            }
        }
        return pointing
    }
    
    func isRightHandPointing() -> Bool {
        var pointing = false
        if (handManager.rightHandPresent() && handManager.rightHand != nil){
            if let hand = handManager.rightHand {
                pointing = isHandPointing(hand: hand)
            }
        }
        return pointing
    }
}
