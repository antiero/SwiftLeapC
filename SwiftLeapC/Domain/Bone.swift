//
//  Bone.swift
//  SwiftLeapC
//

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
