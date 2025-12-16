//  TO REMOVE
//  SceneKitHandRenderer.swift
//  SwiftLeapC
//
//  SceneKit-specific implementation of Hand3DRendererDriver.
//  This file is in the "quarantine zone" for SceneKit.
//  Copyright © 2025 Antony Nasce. All rights reserved.

import SceneKit

final class SceneKitHandRenderer: NSObject, Hand3DRendererDriver, SCNSceneRendererDelegate {

    private weak var containerView: NSView?
    private var scnView: SCNView?

    private let store: HandTrackingStore

    // Shared hand materials (one per hand)
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
    private var leftRig: HandRig?
    private var rightRig: HandRig?

    private var rigConfig: HandRigConfig {
        HandRigConfig(
            showPinchIndicators: showPinchIndicators,
            joinThumbProximal: joinThumbProximal,
            joinMetacarpals: joinMetacarpals,
            showPinkyMetacarpal: showPinkyMetacarpal
        )
    }

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
        self.sphereRadius = sphereRadius
        self.showPinchIndicators = showPinchIndicators
        self.joinThumbProximal = joinThumbProximal
        self.joinMetacarpals = joinMetacarpals
        self.showPinkyMetacarpal = showPinkyMetacarpal
        self.showExtendedFingerIndicators = showExtendedFingerIndicators
        super.init()

        leftHandMaterial.diffuse.contents = leftHandColor
        rightHandMaterial.diffuse.contents = rightHandColor
    }

    deinit {
        detach()
    }

    // MARK: - Hand3DRendererDriver

    func attach(to containerView: NSView) {
        detach() // ensure clean re-attach

        self.containerView = containerView

        let scnView = SCNView(frame: containerView.bounds)
        scnView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(scnView)
        NSLayoutConstraint.activate([
            scnView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scnView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scnView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scnView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        self.scnView = scnView

        // Scene
        let scene = loadHandScene()
        scnView.scene = scene

        // View config (match your existing behavior)
        scnView.delegate = self
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true
        scnView.loops = true
        scnView.rendersContinuously = true

        // Build rigs + camera
        let rigs = HandRigFactory.buildRigs(
            in: scene,
            leftSphereGeo: leftSphereGeo,
            rightSphereGeo: rightSphereGeo,
            sphereRadius: sphereRadius,
            showPinchIndicators: showPinchIndicators
        )
        self.leftRig = rigs.0
        self.rightRig = rigs.1

        // Only add a default camera if the scene doesn't already contain one
        if !sceneContainsCamera(scene) {
            HandRigFactory.addDefaultCamera(to: scene)
        }
    }

    func detach() {
        scnView?.delegate = nil
        scnView?.scene = nil
        scnView?.removeFromSuperview()
        scnView = nil

        leftRig = nil
        rightRig = nil
        containerView = nil
    }

    // MARK: - SCNSceneRendererDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let leftRig, let rightRig else { return }

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

    // MARK: - Helpers

    private func loadHandScene() -> SCNScene {
        // Prefer your existing Hand3DScene.scn if it exists in the app bundle
        if let url = Bundle.main.url(forResource: "Hand3DScene", withExtension: "scn"),
           let scene = try? SCNScene(url: url, options: nil) {
            return scene
        }
        // Fallback (shouldn’t normally happen)
        return SCNScene()
    }

    private func sceneContainsCamera(_ scene: SCNScene) -> Bool {
        var found = false
        scene.rootNode.enumerateChildNodes { node, stop in
            if node.camera != nil {
                found = true
                stop.pointee = true
            }
        }
        return found
    }
}
