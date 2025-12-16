//
//  CameraFeedViewController.swift
//  SwiftLeapC
//

import AppKit

final class CameraFeedViewController: NSViewController {

    @IBOutlet weak var cameraImageView: NSImageView!
    @IBOutlet weak var toggleImageViewSwitch: NSSwitch!

    private let store = HandTrackingStore.shared

    private var timer: Timer?
    private var lastCameraSeq: Int = -1

    /// Put camera frames on our own layer so we can do aspect-fill
    /// (NSImageView's built-in scaling is mostly aspect-fit).
    private let cameraLayer = CALayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        store.setCameraPreviewEnabled(true)

        view.wantsLayer = true
        cameraImageView.wantsLayer = true

        // Ensure the image view actually has a backing layer before we add sublayers.
        // (On AppKit this can be nil even after wantsLayer = true, depending on timing.)
        if cameraImageView.layer == nil {
            cameraImageView.layer = CALayer()
        }
        cameraImageView.layer?.masksToBounds = true

        // Configure our sublayer
        // Aspect-fill: fills the view while maintaining aspect ratio, cropping if needed.
        cameraLayer.contentsGravity = .resizeAspectFill
        cameraLayer.isHidden = true
        cameraLayer.contents = nil

        cameraImageView.layer?.addSublayer(cameraLayer)

        // Respect initial switch state from IB
        applySwitchState(animated: false)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // Ensure loop reflects the current switch state
        applySwitchState(animated: false)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        // Keep the camera layer pinned to the image view bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        cameraLayer.frame = cameraImageView.bounds
        // Match retina scaling for crispness
        if let scale = view.window?.backingScaleFactor {
            cameraLayer.contentsScale = scale
        }
        CATransaction.commit()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopUpdateLoop()
    }

    // MARK: - Update loop

    private func startUpdateLoopIfNeeded() {
        guard timer == nil else { return }

        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCameraLayerIfNeeded()
            }
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    private func stopUpdateLoop() {
        timer?.invalidate()
        timer = nil
        lastCameraSeq = -1
    }
    
    // MARK: - Rendering

    @MainActor
    private func updateCameraLayerIfNeeded() {
        guard !cameraImageView.isHidden else { return }

        let (seq, img) = store.latestCameraImageSnapshot()
        guard seq != lastCameraSeq else { return }
        lastCameraSeq = seq

        if let img {
            // Show camera frames on our sublayer.
            // Important: clear the NSImageView's own image, otherwise IB's placeholder
            // (e.g. AppIcon) can remain visible and make it look like nothing updated.
            cameraImageView.image = nil
            cameraLayer.isHidden = false
            cameraLayer.contents = img

            // Defensive fallback: if, for any reason, the layer path isn't active
            // (e.g. the view isn't layer-backed yet), still show something.
            if cameraLayer.superlayer == nil {
                cameraImageView.image = NSImage(cgImage: img,
                                               size: NSSize(width: img.width, height: img.height))
                cameraImageView.imageScaling = .scaleProportionallyUpOrDown
            }
        } else {
            // Show placeholder using NSImageView’s normal path
            cameraLayer.contents = nil
            cameraLayer.isHidden = true
            // TODO: Understand why this is a bad frame momentarily.
            print("img was nil, setting AppIcon")
            //cameraImageView.image = NSImage(named: "AppIcon")
        }
    }

    // MARK: - UI controls

    private func applySwitchState(animated: Bool) {
        if toggleImageViewSwitch.state == .on {
            showImageView()
        } else {
            hideImageView()
        }
    }

    private func hideImageView() {
        cameraImageView.isHidden = true
        stopUpdateLoop()

        cameraLayer.contents = nil
        cameraLayer.isHidden = true
        cameraImageView.image = nil
    }


    private func showImageView() {
        cameraImageView.isHidden = false

        store.setCameraPreviewEnabled(true)
        startUpdateLoopIfNeeded()
        updateCameraLayerIfNeeded()
    }

    @IBAction func HandleImageSwitchChanged(_ sender: NSSwitch) {
        applySwitchState(animated: false)
    }

    deinit {
        stopUpdateLoop()
    }
}
