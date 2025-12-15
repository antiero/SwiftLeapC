//
//  CameraFrame.swift
//  SwiftLeapC
//
//  Domain model for a single grayscale camera image.
//  Copyright © 2025 Antony Nasce. All rights reserved.

import Foundation

/// A single camera frame copied into Swift-owned memory.
///
/// This type is *Domain*-level: no AppKit/SceneKit/CoreImage types here.
public struct CameraFrame: Sendable {
    public let width: Int
    public let height: Int
    public let bytesPerRow: Int
    public let bytesPerPixel: Int
    public let data: Data   // typically 8bpp grayscale

    public init(width: Int, height: Int, bytesPerRow: Int, bytesPerPixel: Int, data: Data) {
        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow
        self.bytesPerPixel = bytesPerPixel
        self.data = data
    }
}
