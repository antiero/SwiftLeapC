//
//  HandGestureState.swift
//  SwiftLeapC
//
//  Pure helpers for derived state.
//

import Foundation

public struct HandGestureThresholds: Sendable {
    public var pinch: Float = 0.8
    public var grab: Float = 0.8

    public init(pinch: Float = 0.8, grab: Float = 0.8) {
        self.pinch = pinch
        self.grab = grab
    }
}

public struct HandGestureState: Sendable {
    public let isPinching: Bool
    public let isGrabbing: Bool

    public init(hand: Hand?, thresholds: HandGestureThresholds = .init()) {
        guard let hand else {
            self.isPinching = false
            self.isGrabbing = false
            return
        }
        self.isPinching = hand.pinchStrength >= thresholds.pinch
        self.isGrabbing = hand.grabStrength >= thresholds.grab
    }
}
