//
//  ExtendedFingerDetector.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 30/06/2023.
//  Copyright © 2023 Kelly Innes. All rights reserved.
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
            pointing = isHandPointing(hand: handManager.leftHand!)
        }
        return pointing
    }
    
    func isRightHandPointing() -> Bool {
        var pointing = false
        if (handManager.rightHandPresent() && handManager.rightHand != nil){
            pointing = isHandPointing(hand: handManager.rightHand!)
        }
        return pointing
    }
}
