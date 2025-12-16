//
//  HandPreviewViewController.swift
//  SwiftLeapC
//

import Cocoa

final class HandPreviewViewController: NSViewController {
    @IBOutlet weak var handPreview: NSView!

    // Config toggles (kept as-is)
    var showPinchIndicators = true
    var joinThumbProximal = true
    var joinMetacarpals = true
    var showPinkyMetacarpal = true
    var showExtendedFingerIndicators = true

    var leftHandColor: NSColor = .blue
    var rightHandColor: NSColor = .red

    let SPHERE_RADIUS: CGFloat = 0.01

    private var rendererDriver: Hand3DRendererDriver?

    override func viewDidLoad() {
        super.viewDidLoad()

        let driver = RealityKitHandRenderer(
            store: HandTrackingStore.shared,
            leftHandColor: leftHandColor,
            rightHandColor: rightHandColor,
            sphereRadius: SPHERE_RADIUS,
            showPinchIndicators: showPinchIndicators,
            joinThumbProximal: joinThumbProximal,
            joinMetacarpals: joinMetacarpals,
            showPinkyMetacarpal: showPinkyMetacarpal,
            showExtendedFingerIndicators: showExtendedFingerIndicators
        )

        rendererDriver = driver
        driver.attach(to: handPreview)
    }

    deinit {
        rendererDriver?.detach()
    }
}
