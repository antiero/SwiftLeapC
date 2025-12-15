//
//  HandRig.swift
//  SwiftLeapC
//
//  Created by ChatGPT (refactor) on 12/12/2025.
//

import SceneKit

enum RigSide {
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
    static let pinkyBaseIndex: Int = 4 * 4  // Pinky finger (digit 4), joint 0 index in joint list
    
    let side: RigSide
    let root: SCNNode
    
    let palmSphere: SCNNode
    let pinkyMetacarpelSphere: SCNNode
    let pinchNode: SCNNode
    
    private var jointNodes: [SCNNode] = []
    private var boneNodes: [SCNNode] = []
    
    private var jointPositions: [SCNVector3] = Array(repeating: SCNVector3Zero, count: HandRig.totalJointCount)
    
    init(
        side: RigSide,
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
        hand: Hand,
        config: HandRigConfig,
        sphereRadius: CGFloat
    ) {
        // Palm position
        setPalmPosition(hand.palmPositionMM.scnMeters)
        
        // Pinch indicator visibility
        // (We respect showPinchIndicators here so it can't be re-enabled by updates.)
        pinchNode.isHidden = (!config.showPinchIndicators) || (hand.pinchStrength < 0.9)
        
        // Digits (thumb->pinky)
        guard hand.digits.count == 5 else { return }
        let fingers = hand.digits
        
        // Joints are indexed by [fingerIx][jointIx] where jointIx is 0..3 (4 joints per finger: each bone's nextJoint)
        // Use the preallocated flat array to avoid per-frame Dictionary allocations.
        var jointValid = Array(repeating: false, count: HandRig.totalJointCount)
        for fingerIx in 0...4 {
            let finger = fingers[fingerIx]
            guard finger.bones.count == 4 else { continue }
            for jointIx in 0...3 {
                let idx = HandRig.fingerJointIndex(digitIndex: fingerIx, jointIndex: jointIx)
                let positionMM = finger.bones[jointIx].nextJointMM
                let vec3 = positionMM.scnMeters
                self.jointPositions[idx] = vec3
                jointValid[idx] = true
                if idx < jointNodes.count { jointNodes[idx].position = vec3 }
            }
        }
        
        // Bone updates
        var boneIndex = 0
        
        // Finger segments (3 per finger)
        for fingerIx in 0...4 {
            for jointIx in 0...2 {
                let idxA = HandRig.fingerJointIndex(digitIndex: fingerIx, jointIndex: jointIx)
                let idxB = HandRig.fingerJointIndex(digitIndex: fingerIx, jointIndex: jointIx + 1)
                if jointValid[idxA] && jointValid[idxB] {
                    let a = self.jointPositions[idxA]
                    let b = self.jointPositions[idxB]
                    updateBone(at: boneIndex, from: a, to: b, radius: sphereRadius)
                }
                boneIndex += 1
            }
        }
        
        if config.joinThumbProximal {
            let keyA = HandRig.fingerJointIndex(digitIndex: 0, jointIndex: 0)
            let keyB = HandRig.fingerJointIndex(digitIndex: 1, jointIndex: 0)
            if jointValid[keyA] && jointValid[keyB] {
                let a = self.jointPositions[keyA]
                let b = self.jointPositions[keyB]
                updateBone(at: boneIndex, from: a, to: b, radius: sphereRadius)
            }
            boneIndex += 1
        }
        
        // Metacarpals (index->middle->ring->pinky)
        if config.joinMetacarpals {
            for i in 1...3 {
                let keyA = HandRig.fingerJointIndex(digitIndex: i, jointIndex: 0)
                let keyB = HandRig.fingerJointIndex(digitIndex: i + 1, jointIndex: 0)
                if jointValid[keyA] && jointValid[keyB] {
                    let a = jointPositions[keyA]
                    let b = jointPositions[keyB]
                    updateBone(at: boneIndex, from: a, to: b, radius: sphereRadius)
                } else {
                    boneNodes[boneIndex].isHidden = true   // optional, but prevents “stale” cylinders
                }
                boneIndex += 1
            }
        }
        
        // Pinky metacarpal helper (preserves previous behavior)
        if config.showPinkyMetacarpal, hand.digits.count == 5 {
            // CapsuleHand-style helper: uses pinky metacarpal *prevJoint* and thumb (actually index!) metacarpal *prevJoint*.
            let pinky = hand.digits[4]
            let thumb = hand.digits[0]
            if pinky.bones.count > 0, thumb.bones.count > 0 {
                let pinkyMetacarpalPrev = pinky.bones[0].prevJointMM.scnMeters
                let indexMetacarpalPrev = thumb.bones[0].prevJointMM.scnMeters
                
                // Optional: show the helper sphere at the pinky metacarpal prev joint.
                pinkyMetacarpelSphere.position = pinkyMetacarpalPrev
                pinkyMetacarpelSphere.isHidden = false
                
                updateBone(at: boneIndex, from: indexMetacarpalPrev, to: pinkyMetacarpalPrev, radius: sphereRadius)
                boneIndex += 1
                
                // Cylinder: pinky metacarpal <-> pinky base knuckle (PINKY_BASE_INDEX)
                let pinkyBaseKey = HandRig.pinkyBaseIndex
                if jointValid[pinkyBaseKey] {
                    let pinkyBase = self.jointPositions[pinkyBaseKey]
                    updateBone(at: boneIndex, from: pinkyMetacarpalPrev, to: pinkyBase, radius: sphereRadius)
                    boneNodes[boneIndex].isHidden = false
                } else {
                    boneNodes[boneIndex].isHidden = true
                }
                boneIndex += 1
            } else {
                pinkyMetacarpelSphere.isHidden = true
            }
        } else {
            pinkyMetacarpelSphere.isHidden = true
        }
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
    // MARK: - Joint indexing helpers
    
    private static let jointsPerFinger = 4
    
    /// Maps (digitIndex 0-4, jointIndex 0-3) into a flat joint-node array (4 joints per finger).
    private static func fingerJointIndex(digitIndex: Int, jointIndex: Int) -> Int {
        precondition((0..<5).contains(digitIndex), "digitIndex must be 0...4")
        precondition((0..<Self.jointsPerFinger).contains(jointIndex), "jointIndex must be 0...3")
        return digitIndex * Self.jointsPerFinger + jointIndex
    }
    
    /// Maps (digitIndex 0-4, boneIndex 0-2) to the *end joint* of that segment (1-3).
    private static func fingerJointIndex(digitIndex: Int, boneIndex: Int) -> Int {
        precondition((0..<5).contains(digitIndex), "digitIndex must be 0...4")
        precondition((0..<3).contains(boneIndex), "boneIndex must be 0...2")
        // segment 0 ends at joint 1, segment 2 ends at joint 3
        return digitIndex * Self.jointsPerFinger + (boneIndex + 1)
    }
}
