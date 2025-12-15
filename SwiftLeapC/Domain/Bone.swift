//
//  Bone.swift
//  SwiftLeapC
//
//  Copyright © 2025 Antony Nasce. All rights reserved.

import Foundation
import simd

public struct Bone: Sendable {
    public let prevJointMM: SIMD3<Float>
    public let nextJointMM: SIMD3<Float>

    public init(prevJointMM: SIMD3<Float>, nextJointMM: SIMD3<Float>) {
        self.prevJointMM = prevJointMM
        self.nextJointMM = nextJointMM
    }
}
