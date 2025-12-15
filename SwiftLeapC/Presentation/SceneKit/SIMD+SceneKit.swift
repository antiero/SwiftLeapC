//
//  SIMD+SceneKit.swift
//  SwiftLeapC
//

import Foundation
import SceneKit
import simd

public extension SIMD3 where Scalar == Float {
    /// Interprets this vector as millimeters and converts to SceneKit meters.
    var scnMeters: SCNVector3 {
        SCNVector3(0.001 * x, 0.001 * y, 0.001 * z)
    }
}
