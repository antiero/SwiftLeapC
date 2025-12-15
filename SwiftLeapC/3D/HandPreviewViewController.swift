//
//  HandPreviewViewController.swift
//  SwiftLeapC
//
//  Copyright © 2025 Antony Nasce. All rights reserved.

import SceneKit

class HandPreviewViewController: NSViewController, SCNSceneRendererDelegate {
    
    @IBOutlet weak var handPreview: SCNView!
    
    private let store = HandTrackingStore.shared
    
    // Shared hand materials (one per hand). Changing diffuse updates all nodes using that geometry.
    private let leftHandMaterial = SCNMaterial()
    private let rightHandMaterial = SCNMaterial()
    
    var leftHandColor: NSColor = .blue { didSet { leftHandMaterial.diffuse.contents = leftHandColor } }
    var rightHandColor: NSColor = .red { didSet { rightHandMaterial.diffuse.contents = rightHandColor } }
        
    // Config toggles (kept as-is)
    var showPinchIndicators = true
    var joinThumbProximal = true
    var joinMetacarpals = true
    var showPinkyMetacarpal = true
    var showExtendedFingerIndicators = true
    
    // Scene scale / sizes
    let SPHERE_RADIUS: CGFloat = 0.01
    
    private lazy var leftSphereGeo: SCNSphere = {
        let g = SCNSphere(radius: SPHERE_RADIUS)
        g.firstMaterial = leftHandMaterial
        return g
    }()
    
    private lazy var rightSphereGeo: SCNSphere = {
        let g = SCNSphere(radius: SPHERE_RADIUS)
        g.firstMaterial = rightHandMaterial
        return g
    }()
    
    // Hand rigs
    private var leftRig: HandRig!
    private var rightRig: HandRig!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftHandMaterial.diffuse.contents = leftHandColor
        rightHandMaterial.diffuse.contents = rightHandColor
        
        // Use the scene from Interface Builder if available (Hand3DScene.scn),
        // otherwise create a fresh one.
        let scene: SCNScene
        if let existing = handPreview.scene {
            scene = existing
        } else {
            print("No scene attached in IB, creating a new one.")
            scene = SCNScene()
            handPreview.scene = scene
        }
        
        // Configure SCNView + delegate so renderer(updateAtTime:) will fire
        handPreview.delegate = self
        handPreview.allowsCameraControl = true
        handPreview.showsStatistics = true
        handPreview.autoenablesDefaultLighting = true
        
        // Use this to toggle the hand preview on/off
        handPreview.isPlaying = true
        handPreview.loops = true
        handPreview.rendersContinuously = true // useful during development
        
        // Build rigs + camera (same visuals, fewer lines in this controller)
        (leftRig, rightRig) = HandRigFactory.buildRigs(
            in: scene,
            leftSphereGeo: leftSphereGeo,
            rightSphereGeo: rightSphereGeo,
            sphereRadius: SPHERE_RADIUS,
            showPinchIndicators: showPinchIndicators
        )
        HandRigFactory.addDefaultCamera(to: scene)
    }
    
    deinit {
        handPreview?.delegate = nil
        handPreview?.scene = nil
    }
    
    private var rigConfig: HandRigConfig {
        HandRigConfig(
            showPinchIndicators: showPinchIndicators,
            joinThumbProximal: joinThumbProximal,
            joinMetacarpals: joinMetacarpals,
            showPinkyMetacarpal: showPinkyMetacarpal
        )
    }
    
    // MARK: - Renderer delegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = store.latestFrameSnapshot() else {
            leftRig.setHidden(true)
            rightRig.setHidden(true)
            return
        }
        
        if let rightHand = frame.right {
            rightRig.setHidden(false)
            rightRig.update(hand: rightHand, config: rigConfig, sphereRadius: SPHERE_RADIUS)
        } else {
            rightRig.setHidden(true)
        }
        
        if let leftHand = frame.left {
            leftRig.setHidden(false)
            leftRig.update(hand: leftHand, config: rigConfig, sphereRadius: SPHERE_RADIUS)
        } else {
            leftRig.setHidden(true)
        }
    }
}
