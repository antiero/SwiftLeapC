//
//  File.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 30/06/2023.
//  Copyright © 2023 Kelly Innes. All rights reserved.
//

import Foundation

class LeapPinchDetector : ObservableObject {
    
    let handManager = LeapHandManager.sharedInstance
    static let sharedInstance = LeapPinchDetector()
    private let PINCH_THRESHOLD : Float = 0.8
    @Published var leftPinching : Bool = false
    @Published var rightPinching : Bool = false
    
    func leftIsPinching() -> Bool {
        var test = false
        if (handManager.leftHand != nil){
            if let pinchStrength = handManager.leftHand?.pinch_strength, pinchStrength > PINCH_THRESHOLD {
                test = true
                leftPinching = true
            }
            else{
                leftPinching = false
            }
        }
        return test
    }
    
    func rightIsPinching() -> Bool {
        var test = false
        if (handManager.rightHand != nil){
            if let pinchStrength = handManager.rightHand?.pinch_strength, pinchStrength > PINCH_THRESHOLD {
                test = true
                rightPinching = true
            }
            else {
                rightPinching = false
            }
        }
        return test
    }
}
