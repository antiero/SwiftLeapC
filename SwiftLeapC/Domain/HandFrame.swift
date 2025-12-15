//
//  HandFrame.swift
//  SwiftLeapC
//
//  Domain model: pure Swift value types (no LeapC / AppKit / SceneKit).
//

import Foundation
import simd

public struct HandFrame: Sendable {
    public let id: Int64
    public let timestamp: Int64
    public let left: Hand?
    public let right: Hand?

    public init(id: Int64, timestamp: Int64, left: Hand?, right: Hand?) {
        self.id = id
        self.timestamp = timestamp
        self.left = left
        self.right = right
    }
}
