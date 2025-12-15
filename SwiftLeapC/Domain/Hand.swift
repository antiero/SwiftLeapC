//
//  Hand.swift
//  SwiftLeapC
//

import Foundation
import simd

public enum Chirality: Sendable {
    case left
    case right
}

public struct Hand: Sendable {
    public let chirality: Chirality
    public let palmPositionMM: SIMD3<Float>
    public let pinchStrength: Float
    public let grabStrength: Float
    public let digits: [Digit]   // thumb..pinky (count == 5)

    public init(chirality: Chirality,
                palmPositionMM: SIMD3<Float>,
                pinchStrength: Float,
                grabStrength: Float,
                digits: [Digit]) {
        self.chirality = chirality
        self.palmPositionMM = palmPositionMM
        self.pinchStrength = pinchStrength
        self.grabStrength = grabStrength
        self.digits = digits
    }
}
