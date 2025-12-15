//
//  Digit.swift
//  SwiftLeapC
//

import Foundation

public struct Digit: Sendable {
    public let fingerID: Int32
    public let isExtended: Bool
    public let bones: [Bone] // metacarpal..distal (count == 4)

    public init(fingerID: Int32, isExtended: Bool, bones: [Bone]) {
        self.fingerID = fingerID
        self.isExtended = isExtended
        self.bones = bones
    }
}
