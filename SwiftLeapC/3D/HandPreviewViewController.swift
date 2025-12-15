//
//  HandPreviewViewController.swift
//  SwiftLeapC
//
//  Copyright © 2025 Antony Nasce. All rights reserved.

import SceneKit

final class HandPreviewViewController: NSViewController {

    @IBOutlet weak var handPreview: SCNView!

    // Config toggles (kept as-is)
    var showPinchIndicators = true
    var joinThumbProximal = true
    var joinMetacarpals = true
    var showPinkyMetacarpal = true
    var showExtendedFingerIndicators = true

    var leftHandColor: NSColor = .blue
    var rightHandColor: NSColor = .red

    // Scene scale / sizes
    let SPHERE_RADIUS: CGFloat = 0.01

    private var rendererDriver: SceneKitHandRenderer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // SceneKit rendering (isolated behind SceneKitHandRenderer)
        rendererDriver = SceneKitHandRenderer(
            scnView: handPreview,
            store: .shared,
            leftHandColor: leftHandColor,
            rightHandColor: rightHandColor,
            sphereRadius: SPHERE_RADIUS,
            showPinchIndicators: showPinchIndicators,
            joinThumbProximal: joinThumbProximal,
            joinMetacarpals: joinMetacarpals,
            showPinkyMetacarpal: showPinkyMetacarpal,
            showExtendedFingerIndicators: showExtendedFingerIndicators
        )
    }

    deinit {
        handPreview?.delegate = nil
        handPreview?.scene = nil
    }
}
