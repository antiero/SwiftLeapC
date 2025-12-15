//
//  LeapEventMapper.swift
//  SwiftLeapC
//
//  LeapC -> Domain conversion.
//

import Foundation
import simd

// LeapC types are available via the bridging header (LeapC.h).
// This file intentionally does NOT import AppKit/SceneKit.

enum LeapEventMapper {
    
    static func mapTrackingEvent(_ event: LEAP_TRACKING_EVENT) -> HandFrame {
        var left: Hand? = nil
        var right: Hand? = nil
        
        for i in 0 ..< event.nHands {
            let leapHand = event.pHands.advanced(by: Int(i)).pointee
            let hand = mapHand(leapHand)
            switch hand.chirality {
            case .left:  left = hand
            case .right: right = hand
            }
        }
        
        return HandFrame(
            id: Int64(event.tracking_frame_id),
            timestamp: Int64(event.info.timestamp),
            left: left,
            right: right
        )
    }
    
    static func mapImageEvent(_ event: LEAP_IMAGE_EVENT) -> CameraFrame? {
        // LeapC exposes stereo images (left + right). In Swift, the fixed-size C array
        // imports as a tuple: (LEAP_IMAGE, LEAP_IMAGE).
        let img = event.image.0 // left camera by default
        
        let props = img.properties
        let width = Int(props.width)
        let height = Int(props.height)
        let bytesPerPixel = Int(props.bpp)
        
        guard width > 0, height > 0, bytesPerPixel > 0 else { return nil }
        guard let basePtr = img.data else { return nil }
        
        // Leap provides an offset into the buffer.
        let offset = Int(img.offset)
        
        // Assume tightly-packed rows. If your SDK provides a row stride, prefer that.
        let bytesPerRow = width * bytesPerPixel
        let byteCount = bytesPerRow * height
        guard byteCount > 0 else { return nil }
        
        let start = UnsafeRawPointer(basePtr).advanced(by: offset)
        let data = Data(bytes: start, count: byteCount)
        
        return CameraFrame(
            width: width,
            height: height,
            bytesPerRow: bytesPerRow,
            bytesPerPixel: bytesPerPixel,
            data: data
        )
    }
    
    static func mapHand(_ h: LEAP_HAND) -> Hand {
        let chirality: Chirality = (h.type == eLeapHandType_Left) ? .left : .right
        let palm = h.palm.position
        let palmMM = SIMD3<Float>(palm.x, palm.y, palm.z)
        
        // C arrays import as fixed-size tuples in Swift. Build a Swift array.
        let digitsTuple = h.digits
        let leapDigits: [LEAP_DIGIT] = [digitsTuple.0, digitsTuple.1, digitsTuple.2, digitsTuple.3, digitsTuple.4]
        let digits: [Digit] = leapDigits.map { mapDigit($0) }
        
        return Hand(
            chirality: chirality,
            palmPositionMM: palmMM,
            pinchStrength: Float(h.pinch_strength),
            grabStrength: Float(h.grab_strength),
            digits: digits
        )
    }
    
    static func mapDigit(_ d: LEAP_DIGIT) -> Digit {
        let bonesTuple = d.bones
        let leapBones: [LEAP_BONE] = [bonesTuple.0, bonesTuple.1, bonesTuple.2, bonesTuple.3]
        let bones: [Bone] = leapBones.map { mapBone($0) }
        return Digit(
            fingerID: d.finger_id,
            isExtended: d.is_extended != 0,
            bones: bones
        )
    }
    
    static func mapBone(_ b: LEAP_BONE) -> Bone {
        let p = b.prev_joint
        let n = b.next_joint
        return Bone(
            prevJointMM: SIMD3<Float>(p.x, p.y, p.z),
            nextJointMM: SIMD3<Float>(n.x, n.y, n.z)
        )
    }
}
