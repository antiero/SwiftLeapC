//
//  SceneKitHandRenderer.swift
//  SwiftLeapC
//
//  SceneKit-specific 3D hand rendering driver.
//  Keeps SceneKit contained so we can swap to RealityKit later.
//
//  Copyright © 2025 Antony Nasce. All rights reserved.
//

import SceneKit

final class SceneKitHandRenderer: NSObject, SCNSceneRendererDelegate {

    private weak var scnView: SCNView?
    private let store: HandTrackingStore

    // Shared hand materials (one per hand). Changing diffuse updates all nodes using that material/geometry.
    private let leftHandMaterial = SCNMaterial()
    private let rightHandMaterial = SCNMaterial()

    var leftHandColor: NSColor = .blue {
        didSet { leftHandMaterial.diffuse.contents = leftHandColor }
    }

    var rightHandColor: NSColor = .red {
        didSet { rightHandMaterial.diffuse.contents = rightHandColor }
    }

    // Config toggles
    var showPinchIndicators: Bool
    var joinThumbProximal: Bool
    var joinMetacarpals: Bool
    var showPinkyMetacarpal: Bool
    var showExtendedFingerIndicators: Bool

    // Scene scale / sizes
    let sphereRadius: CGFloat

    private lazy var leftSphereGeo: SCNSphere = {
        let g = SCNSphere(radius: sphereRadius)
        g.firstMaterial = leftHandMaterial
        return g
    }()

    private lazy var rightSphereGeo: SCNSphere = {
        let g = SCNSphere(radius: sphereRadius)
        g.firstMaterial = rightHandMaterial
        return g
    }()

    // Hand rigs
    private var leftRig: HandRig!
    private var rightRig: HandRig!

    private var rigConfig: HandRigConfig {
        HandRigConfig(
            showPinchIndicators: showPinchIndicators,
            joinThumbProximal: joinThumbProximal,
            joinMetacarpals: joinMetacarpals,
            showPinkyMetacarpal: showPinkyMetacarpal
        )
    }

    init(
        scnView: SCNView,
        store: HandTrackingStore = .shared,
        leftHandColor: NSColor = .blue,
        rightHandColor: NSColor = .red,
        sphereRadius: CGFloat = 0.01,
        showPinchIndicators: Bool = true,
        joinThumbProximal: Bool = true,
        joinMetacarpals: Bool = true,
        showPinkyMetacarpal: Bool = true,
        showExtendedFingerIndicators: Bool = true
    ) {
        self.scnView = scnView
        self.store = store
        self.leftHandColor = leftHandColor
        self.rightHandColor = rightHandColor
        self.sphereRadius = sphereRadius
        self.showPinchIndicators = showPinchIndicators
        self.joinThumbProximal = joinThumbProximal
        self.joinMetacarpals = joinMetacarpals
        self.showPinkyMetacarpal = showPinkyMetacarpal
        self.showExtendedFingerIndicators = showExtendedFingerIndicators
        super.init()

        configureSceneAndView()
    }

    deinit {
        scnView?.delegate = nil
    }

    private func configureSceneAndView() {
        guard let scnView else { return }

        leftHandMaterial.diffuse.contents = leftHandColor
        rightHandMaterial.diffuse.contents = rightHandColor

        // Use the scene from Interface Builder if available (Hand3DScene.scn),
        // otherwise create a fresh one.
        let scene: SCNScene
        if let existing = scnView.scene {
            scene = existing
        } else {
            print("No scene attached in IB, creating a new one.")
            scene = SCNScene()
            scnView.scene = scene
        }

        // Configure SCNView + delegate so renderer(updateAtTime:) will fire
        scnView.delegate = self
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.autoenablesDefaultLighting = true

        // Use this to toggle the hand preview on/off
        scnView.isPlaying = true
        scnView.loops = true
        scnView.rendersContinuously = true // useful during development

        // Build rigs + camera (same visuals, SceneKit isolated here)
        (leftRig, rightRig) = HandRigFactory.buildRigs(
            in: scene,
            leftSphereGeo: leftSphereGeo,
            rightSphereGeo: rightSphereGeo,
            sphereRadius: sphereRadius,
            showPinchIndicators: showPinchIndicators
        )
        HandRigFactory.addDefaultCamera(to: scene)
    }

    // MARK: - SCNSceneRendererDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = store.latestFrameSnapshot() else {
            leftRig.setHidden(true)
            rightRig.setHidden(true)
            return
        }

        if let rightHand = frame.right {
            rightRig.setHidden(false)
            rightRig.update(hand: rightHand, config: rigConfig, sphereRadius: sphereRadius)
        } else {
            rightRig.setHidden(true)
        }

        if let leftHand = frame.left {
            leftRig.setHidden(false)
            leftRig.update(hand: leftHand, config: rigConfig, sphereRadius: sphereRadius)
        } else {
            leftRig.setHidden(true)
        }
    }
}
