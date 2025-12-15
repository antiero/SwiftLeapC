//
//  Hand.swift
//  SwiftLeapC
//

import Foundation
import simd

public enum HandSide: Sendable {
    case left
    case right
}

public struct Hand: Sendable {
    public let side: HandSide
    public let palmPositionMM: SIMD3<Float>
    public let pinchStrength: Float
    public let grabStrength: Float
    public let digits: [Digit]   // thumb..pinky (count == 5)

    public init(side: HandSide,
                palmPositionMM: SIMD3<Float>,
                pinchStrength: Float,
                grabStrength: Float,
                digits: [Digit]) {
        self.side = side
        self.palmPositionMM = palmPositionMM
        self.pinchStrength = pinchStrength
        self.grabStrength = grabStrength
        self.digits = digits
    }
}
