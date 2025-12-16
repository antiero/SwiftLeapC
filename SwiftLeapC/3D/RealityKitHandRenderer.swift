//
//  RealityKitHandRenderer.swift
//  SwiftLeapC
//

import AppKit
import RealityKit
import Combine
import simd

final class RealityKitHandRenderer: Hand3DRendererDriver {

    // MARK: - Config (parity with SceneKit)

    var showPinchIndicators: Bool
    var joinThumbProximal: Bool          // SceneKit actually connects thumb base -> index base
    var joinMetacarpals: Bool            // SceneKit connects index->middle->ring->pinky
    var showPinkyMetacarpal: Bool        // SceneKit helper sphere + 2 helper cylinders
    var showExtendedFingerIndicators: Bool // parity flag; not used yet

    let sphereRadius: Float
    var leftHandColor: NSColor
    var rightHandColor: NSColor

    private let store: HandTrackingStore

    // MARK: - RealityKit

    private weak var containerView: NSView?
    private var arView: ARView?
    private var updateSub: Cancellable?

    private var rootAnchor: AnchorEntity?

    private var leftRig: RKHandRig?
    private var rightRig: RKHandRig?

    // MARK: - Scratch buffers (no per-frame allocations)

    private static let totalJointCount = 20 // 5 fingers * 4 joints
    private static let pinkyBaseIndex = 16  // digit 4, joint 0 => 4*4

    private var jointPositionsScratch = [SIMD3<Float>](repeating: .zero, count: totalJointCount)
    private var jointValidScratch = [Bool](repeating: false, count: totalJointCount)

    // MARK: - Init

    @MainActor
    init(
        store: HandTrackingStore,
        leftHandColor: NSColor = .blue,
        rightHandColor: NSColor = .red,
        sphereRadius: CGFloat = 0.01,
        showPinchIndicators: Bool = true,
        joinThumbProximal: Bool = true,
        joinMetacarpals: Bool = true,
        showPinkyMetacarpal: Bool = true,
        showExtendedFingerIndicators: Bool = true
    ) {
        self.store = store
        self.leftHandColor = leftHandColor
        self.rightHandColor = rightHandColor
        self.sphereRadius = Float(sphereRadius)

        self.showPinchIndicators = showPinchIndicators
        self.joinThumbProximal = joinThumbProximal
        self.joinMetacarpals = joinMetacarpals
        self.showPinkyMetacarpal = showPinkyMetacarpal
        self.showExtendedFingerIndicators = showExtendedFingerIndicators
    }

    deinit { detach() }

    // MARK: - Hand3DRendererDriver

    func attach(to containerView: NSView) {
        detach()

        self.containerView = containerView

        let arView = ARView(frame: .zero)
        arView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(arView)
        NSLayoutConstraint.activate([
            arView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            arView.topAnchor.constraint(equalTo: containerView.topAnchor),
            arView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        self.arView = arView

        arView.debugOptions = [.showStatistics]
        arView.environment.background = .color(.lightGray)

        arView.scene.anchors.removeAll()
        let anchor = AnchorEntity(world: .zero)
        self.rootAnchor = anchor
        arView.scene.addAnchor(anchor)

        // Camera (same as SceneKit default camera)
        let camera = PerspectiveCamera()
        camera.look(at: SIMD3<Float>(0, 0.2, 0),
                    from: SIMD3<Float>(0, 0.2, 0.7),
                    relativeTo: nil)
        anchor.addChild(camera)

        // Simple directional light (we’ll improve later)
        let light = DirectionalLight()
        light.light.intensity = 25_000
        light.look(at: SIMD3<Float>(0, 0, 0),
                   from: SIMD3<Float>(0.3, 0.8, 0.6),
                   relativeTo: nil)
        anchor.addChild(light)

        // Rigs (match SceneKit colors)
        let leftRig = RKHandRig(handColor: leftHandColor, sphereRadius: self.sphereRadius)
        let rightRig = RKHandRig(handColor: rightHandColor, sphereRadius: self.sphereRadius)
        self.leftRig = leftRig
        self.rightRig = rightRig

        anchor.addChild(leftRig.root)
        anchor.addChild(rightRig.root)

        // Update loop
        updateSub = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            self?.renderLatestFrame()
        }
    }

    func detach() {
        updateSub?.cancel()
        updateSub = nil

        if let anchor = rootAnchor {
            anchor.children.removeAll()
            anchor.removeFromParent()
        }
        rootAnchor = nil

        leftRig = nil
        rightRig = nil

        arView?.removeFromSuperview()
        arView = nil
        containerView = nil
    }

    // MARK: - Rendering

    private func renderLatestFrame() {
        guard let leftRig, let rightRig else { return }

        guard let frame = store.latestFrameSnapshot() else {
            leftRig.setHidden(true)
            rightRig.setHidden(true)
            return
        }

        if let lh = frame.left {
            leftRig.setHidden(false)
            update(hand: lh, rig: leftRig)
        } else {
            leftRig.setHidden(true)
        }

        if let rh = frame.right {
            rightRig.setHidden(false)
            update(hand: rh, rig: rightRig)
        } else {
            rightRig.setHidden(true)
        }
    }

    private func update(hand: Hand, rig: RKHandRig) {
        // Palm
        rig.palm.position = meters(hand.palmPositionMM)

        // Pinch indicator visibility (exact parity)
        rig.pinch.isEnabled = showPinchIndicators && (hand.pinchStrength >= 0.9)

        guard hand.digits.count == 5 else { return }
        let fingers = hand.digits

        // Reset validity flags
        for i in 0..<Self.totalJointCount { jointValidScratch[i] = false }

        // Joints: 4 per finger, from each bone.nextJoint
        for fingerIx in 0..<5 {
            let finger = fingers[fingerIx]
            guard finger.bones.count == 4 else { continue }

            for jointIx in 0..<4 {
                let key = fingerIx * 4 + jointIx
                let pos = meters(finger.bones[jointIx].nextJointMM)

                jointPositionsScratch[key] = pos
                jointValidScratch[key] = true

                rig.joints[key].position = pos
                rig.joints[key].isEnabled = true
            }
        }

        // Hide joints not updated
        for i in 0..<Self.totalJointCount where !jointValidScratch[i] {
            rig.joints[i].isEnabled = false
        }

        // Bone updates (match SceneKit counts/order)
        var boneIndex = 0

        // 1) Finger segments (15 bones: 3 per finger)
        for fingerIx in 0..<5 {
            for jointIx in 0..<3 {
                let aKey = fingerIx * 4 + jointIx
                let bKey = fingerIx * 4 + (jointIx + 1)

                if jointValidScratch[aKey] && jointValidScratch[bKey] {
                    rig.updateBone(at: boneIndex,
                                   from: jointPositionsScratch[aKey],
                                   to: jointPositionsScratch[bKey])
                } else {
                    rig.hideBone(at: boneIndex)
                }
                boneIndex += 1
            }
        }

        // 2) Thumb base -> Index base (SceneKit config.joinThumbProximal behavior)
        if joinThumbProximal {
            let keyA = 0 * 4 + 0 // thumb joint 0
            let keyB = 1 * 4 + 0 // index joint 0
            if jointValidScratch[keyA] && jointValidScratch[keyB] {
                rig.updateBone(at: boneIndex,
                               from: jointPositionsScratch[keyA],
                               to: jointPositionsScratch[keyB])
            } else {
                rig.hideBone(at: boneIndex)
            }
            boneIndex += 1
        }

        // 3) Metacarpals: index->middle->ring->pinky (3 bones, parity)
        if joinMetacarpals {
            for digit in 1..<4 { // 1..3 connects (1->2), (2->3), (3->4)
                let keyA = digit * 4 + 0
                let keyB = (digit + 1) * 4 + 0
                if jointValidScratch[keyA] && jointValidScratch[keyB] {
                    rig.updateBone(at: boneIndex,
                                   from: jointPositionsScratch[keyA],
                                   to: jointPositionsScratch[keyB])
                } else {
                    rig.hideBone(at: boneIndex)
                }
                boneIndex += 1
            }
        }

        // 4) Pinky metacarpal helper (sphere + 2 cylinders), parity with SceneKit
        if showPinkyMetacarpal {
            let pinky = fingers[4]
            let thumb = fingers[0] // SceneKit uses digit 0 bone0 prevJoint here

            if !pinky.bones.isEmpty, !thumb.bones.isEmpty {
                let pinkyMetPrev = meters(pinky.bones[0].prevJointMM)
                let indexMetPrev = meters(thumb.bones[0].prevJointMM)

                // helper sphere at pinky metacarpal prev
                rig.pinkyHelper.position = pinkyMetPrev
                rig.pinkyHelper.isEnabled = true

                // cylinder: indexMetPrev <-> pinkyMetPrev
                rig.updateBone(at: boneIndex, from: indexMetPrev, to: pinkyMetPrev)
                boneIndex += 1

                // cylinder: pinkyMetPrev <-> pinky base knuckle (digit4 joint0)
                let pinkyBaseKey = Self.pinkyBaseIndex
                if jointValidScratch[pinkyBaseKey] {
                    let pinkyBase = jointPositionsScratch[pinkyBaseKey]
                    rig.updateBone(at: boneIndex, from: pinkyMetPrev, to: pinkyBase)
                } else {
                    rig.hideBone(at: boneIndex)
                }
                boneIndex += 1
            } else {
                rig.pinkyHelper.isEnabled = false
            }
        } else {
            rig.pinkyHelper.isEnabled = false
        }

        // Hide any remaining bones (RKHandRig should allocate at least 21)
        rig.hideBones(from: boneIndex)
    }

    private func meters(_ mm: SIMD3<Float>) -> SIMD3<Float> {
        mm * 0.001
    }
}
