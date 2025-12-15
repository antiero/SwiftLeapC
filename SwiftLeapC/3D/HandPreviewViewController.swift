//
//  HandPreviewViewController.swift
//  SwiftLeapC
//

import Cocoa

final class HandPreviewViewController: NSViewController {

    // ✅ IMPORTANT: In Interface Builder, make this view an NSView (not SCNView).
    @IBOutlet weak var handPreview: NSView!

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

    private var rendererDriver: Hand3DRendererDriver?

    override func viewDidLoad() {
        super.viewDidLoad()

        // VC no longer imports/knows SceneKit. It just hosts a renderer driver.
        let driver = SceneKitHandRenderer(
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
        self.rendererDriver = driver
        driver.attach(to: handPreview)
    }

    deinit {
        rendererDriver?.detach()
    }
}
