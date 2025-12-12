//
//  HandRig.swift
//  SwiftLeapC
//
//  Created by ChatGPT (refactor) on 12/12/2025.
//

import Foundation
import AppKit
import SceneKit

enum HandSide {
    case left
    case right

    var handNodeName: String {
        switch self {
        case .left:  return "LeftHand"
        case .right: return "RightHand"
        }
    }

    var jointNodePrefix: String {
        switch self {
        case .left:  return "LeftJoint-"
        case .right: return "RightJoint-"
        }
    }

    var boneNodePrefix: String {
        switch self {
        case .left:  return "LeftBone-"
        case .right: return "RightBone-"
        }
    }

    var pinchIndicatorName: String {
        switch self {
        case .left:  return "LeftPinchIndicator"
        case .right: return "RightPinchIndicator"
        }
    }

    /// Kept for backwards-compat with existing scene expectations.
    var palmNodeName: String {
        switch self {
        case .left:  return "LEFT"
        case .right: return "RIGHT"
        }
    }
}

struct HandRigConfig {
    var showPinchIndicators: Bool
    var joinThumbProximal: Bool
    var joinMetacarpals: Bool
    var showPinkyMetacarpal: Bool

    init(
        showPinchIndicators: Bool = true,
        joinThumbProximal: Bool = true,
        joinMetacarpals: Bool = true,
        showPinkyMetacarpal: Bool = true
    ) {
        self.showPinchIndicators = showPinchIndicators
        self.joinThumbProximal = joinThumbProximal
        self.joinMetacarpals = joinMetacarpals
        self.showPinkyMetacarpal = showPinkyMetacarpal
    }
}

final class HandRig {

    static let totalJointCount: Int = 4 * 5 // 4 joints per finger, 5 fingers
    static let pinkyBaseIndex: Int = 3 * 4  // 4th finger (pinky), joint 0 index in joint list

    let side: HandSide
    let root: SCNNode

    let palmSphere: SCNNode
    let pinkyMetacarpelSphere: SCNNode
    let pinchNode: SCNNode

    private var jointNodes: [SCNNode] = []
    private var boneNodes: [SCNNode] = []

    private var jointPositions: [SCNVector3] = Array(repeating: SCNVector3Zero, count: HandRig.totalJointCount)

    init(
        side: HandSide,
        sphereGeometry: SCNGeometry,
        sphereRadius: CGFloat,
        showPinchIndicators: Bool
    ) {
        self.side = side

        // Root node
        self.root = SCNNode()
        self.root.name = side.handNodeName

        // Palm sphere
        self.palmSphere = SCNNode(geometry: sphereGeometry)
        self.palmSphere.name = side.palmNodeName
        self.root.addChildNode(self.palmSphere)

        // Joint spheres
        for nodeIx in 0..<HandRig.totalJointCount {
            let n = SCNNode(geometry: sphereGeometry)
            n.name = "\(side.jointNodePrefix)\(nodeIx)"
            jointNodes.append(n)
            root.addChildNode(n)
        }

        // Bone cylinders (implemented as a line + rotation on a plain node)
        // NOTE: we pre-create 21 bones because the update path can use:
        // 15 (finger segments) + 1 (thumb->index) + 3 (metacarpals) + 2 (pinky metacarpal helper) = 21
        for boneIx in 0...20 {
            let b = SCNNode()
            b.name = "\(side.boneNodePrefix)\(boneIx)"
            b.updateLineInTwoPointsWithRotation(
                from: SCNVector3(1, 1, 1),
                to: SCNVector3(1, 1, 1),
                radius: sphereRadius * 0.8,
                color: .white
            )
            boneNodes.append(b)
            root.addChildNode(b)
        }

        // Pinky metacarpal indicator sphere (same geo/color as the hand)
        self.pinkyMetacarpelSphere = SCNNode(geometry: sphereGeometry)
        root.addChildNode(self.pinkyMetacarpelSphere)

        // Pinch indicator
        self.pinchNode = SCNNode(geometry: SCNSphere(radius: sphereRadius * 1.5))
        self.pinchNode.geometry?.materials.first?.diffuse.contents = NSColor.systemYellow
        self.pinchNode.name = side.pinchIndicatorName
        root.addChildNode(self.pinchNode)
        self.pinchNode.isHidden = !showPinchIndicators
    }

    func setHidden(_ hidden: Bool) {
        root.isHidden = hidden
    }

    func setPalmPosition(_ position: SCNVector3) {
        palmSphere.position = position
    }

    func update(
        leapHand: LEAP_HAND,
        palmPosition: SCNVector3,
        pinchStrength: Float,
        config: HandRigConfig,
        sphereRadius: CGFloat
    ) {
        setPalmPosition(palmPosition)

        // Pinch indicator visibility
        // (We respect showPinchIndicators here so it can't be re-enabled by updates.)
        pinchNode.isHidden = (!config.showPinchIndicators) || (pinchStrength < 0.9)

        // Digits (thumb->pinky)
        let digits = leapHand.digits
        let thumb  = digits.0
        let index  = digits.1
        let middle = digits.2
        let ring   = digits.3
        let pinky  = digits.4
        let fingers = [thumb, index, middle, ring, pinky]

        // Update joint spheres and cache positions
        for fingerIx in 0...4 {
            let finger = fingers[fingerIx]
            let bones = [finger.bones.0, finger.bones.1, finger.bones.2, finger.bones.3]
            for jointIx in 0...3 {
                let idx = HandRig.fingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
                let position = bones[jointIx].next_joint
                let vec3 = SCNVector3(0.001 * position.x, 0.001 * position.y, 0.001 * position.z)
                jointPositions[idx] = vec3
                jointNodes[idx].position = vec3
            }
        }

        // Bone updates
        var boneIndex = 0

        // Finger segments (3 per finger)
        for fingerIx in 0...4 {
            for jointIx in 0...2 {
                let keyA = HandRig.fingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
                let keyB = HandRig.fingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx + 1)
                updateBone(at: boneIndex, from: jointPositions[keyA], to: jointPositions[keyB], radius: sphereRadius)
                boneIndex += 1
            }
        }

        // Thumb proximal to index proximal
        if config.joinThumbProximal {
            let keyA = HandRig.fingerJointIndex(fingerIndex: 0, jointIndex: 0)
            let keyB = HandRig.fingerJointIndex(fingerIndex: 1, jointIndex: 0)
            updateBone(at: boneIndex, from: jointPositions[keyA], to: jointPositions[keyB], radius: sphereRadius)
            boneIndex += 1
        }

        // Metacarpals (index->middle->ring->pinky)
        if config.joinMetacarpals {
            for i in 1...3 {
                let keyA = HandRig.fingerJointIndex(fingerIndex: i, jointIndex: 0)
                let keyB = HandRig.fingerJointIndex(fingerIndex: i + 1, jointIndex: 0)
                updateBone(at: boneIndex, from: jointPositions[keyA], to: jointPositions[keyB], radius: sphereRadius)
                boneIndex += 1
            }
        }

        // Pinky metacarpal helper (matches the previous behavior in HandPreviewViewController)
        if config.showPinkyMetacarpal {
            let pinkyMetacarpal = pinky.metacarpal.prev_joint
            let indexMetacarpal = thumb.metacarpal.prev_joint // (kept as-is from your original code)

            let vecA = SCNVector3(0.001 * pinkyMetacarpal.x, 0.001 * pinkyMetacarpal.y, 0.001 * pinkyMetacarpal.z)
            let vecB = SCNVector3(0.001 * indexMetacarpal.x, 0.001 * indexMetacarpal.y, 0.001 * indexMetacarpal.z)

            pinkyMetacarpelSphere.position = vecA
            updateBoneNode(boneNodes[boneIndex], from: vecA, to: vecB, radius: sphereRadius)
            boneIndex += 1

            // The second helper bone goes from the metacarpal marker to the pinky base joint.
            updateBoneNode(boneNodes[boneIndex], from: vecA, to: jointPositions[HandRig.pinkyBaseIndex], radius: sphereRadius)
        }
    }

    // MARK: - Helpers

    private static func fingerJointIndex(fingerIndex: Int, jointIndex: Int) -> Int {
        return fingerIndex * 4 + jointIndex
    }

    private func updateBone(at index: Int, from: SCNVector3, to: SCNVector3, radius: CGFloat) {
        guard index >= 0 && index < boneNodes.count else { return }
        updateBoneNode(boneNodes[index], from: from, to: to, radius: radius)
    }

    private func updateBoneNode(_ node: SCNNode, from: SCNVector3, to: SCNVector3, radius: CGFloat) {
        node.updateLineInTwoPointsWithRotation(
            from: from,
            to: to,
            radius: radius,
            color: .white
        )
    }
}