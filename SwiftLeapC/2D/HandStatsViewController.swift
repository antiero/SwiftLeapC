//
//  HandStatsViewController.swift
//  SwiftLeapC
//
//  AppKit UI fed by Domain models via HandTrackingStore.
//  Copyright © 2025 Antony Nasce. All rights reserved.

import AppKit
import Combine

final class HandStatsViewController: NSViewController {

    // MARK: - Outlets (wired from Interface Builder for now)

    @IBOutlet weak var rightGrabImage: NSImageView!
    @IBOutlet weak var rightPinchImage: NSImageView!
    @IBOutlet weak var leftGrabImage: NSImageView!
    @IBOutlet weak var leftPinchImage: NSImageView!

    @IBOutlet weak var rightGrabIndicator: NSLevelIndicator!
    @IBOutlet weak var leftGrabIndicator: NSLevelIndicator!
    @IBOutlet weak var leftPinchIndicator: NSLevelIndicator!
    @IBOutlet weak var rightPinchIndicator: NSLevelIndicator!

    @IBOutlet weak var leftPinchAmountTextField: NSTextField!
    @IBOutlet weak var leftGrabAmountTextField: NSTextField!
    @IBOutlet weak var rightPinchAmountTextField: NSTextField!
    @IBOutlet weak var rightGrabAmountTextField: NSTextField!

    @IBOutlet weak var cameraImageView: NSImageView!
    @IBOutlet weak var toggleStatsViewSwitch: NSSwitch!
    @IBOutlet weak var toggleImageViewSwitch: NSSwitch!
    

    // MARK: - Dependencies

    private let store = HandTrackingStore.shared
    private let thresholds = HandGestureThresholds(pinch: 0.8, grab: 0.8)

    private var cancellables = Set<AnyCancellable>()
    private var keyBoardMonitor: Any?

    // Coalesce high-frequency updates into a single UI update on the main thread.
    private let uiUpdateLock = NSLock()
    private var uiUpdateScheduled = false
    private var didRegisterObservers = false

    // MARK: - Setup

    func initLeapStats() {
        if didRegisterObservers { return }
        didRegisterObservers = true

        leftPinchIndicator.warningValue = Double(thresholds.pinch)
        rightPinchIndicator.warningValue = Double(thresholds.pinch)
        leftGrabIndicator.warningValue = Double(thresholds.grab)
        rightGrabIndicator.warningValue = Double(thresholds.grab)

        // Render camera frames via CALayer contents (CGImage) to avoid NSImage snapshot churn.
        cameraImageView.wantsLayer = true
        cameraImageView.layer?.contentsGravity = .resizeAspect

        // Allow background colors on the small state images
        [leftPinchImage, rightPinchImage, leftGrabImage, rightGrabImage].forEach {
            $0?.wantsLayer = true
            $0?.layer?.cornerRadius = 6
            $0?.layer?.masksToBounds = true
        }

        store.$frame
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.scheduleUIUpdate() }
            .store(in: &cancellables)

        store.$cameraImage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.scheduleUIUpdate() }
            .store(in: &cancellables)

        store.$status
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                guard let self else { return }
                
            // TODO: Add a label to the UI
            //self.connectionStatusLabel.stringValue = status.description
                
            if status == .connectionLost {
                    Task { @MainActor in self.showDisconnectedUI() }
                }
            }
            .store(in: &cancellables)

        keyBoardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: myKeyDownEvent)

        // Initially hide the image preview
        hideImageView()
    }

    // MARK: - UI update plumbing

    private func scheduleUIUpdate() {
        uiUpdateLock.lock()
        defer { uiUpdateLock.unlock() }

        guard !uiUpdateScheduled else { return }
        uiUpdateScheduled = true

        Task { @MainActor [weak self] in
            self?.performUIUpdate()
        }
    }

    @MainActor
    private func performUIUpdate() {
        defer {
            uiUpdateLock.lock()
            uiUpdateScheduled = false
            uiUpdateLock.unlock()
        }

        // Don't bother to update if the view is not shown...
        if view.isHidden { return }

        let frame = store.frame
        let leftState = HandGestureState(hand: frame?.left, thresholds: thresholds)
        let rightState = HandGestureState(hand: frame?.right, thresholds: thresholds)

        let leftPinch = frame?.left?.pinchStrength ?? 0
        let rightPinch = frame?.right?.pinchStrength ?? 0
        let leftGrab = frame?.left?.grabStrength ?? 0
        let rightGrab = frame?.right?.grabStrength ?? 0

        leftPinchIndicator.doubleValue = Double(leftPinch)
        rightPinchIndicator.doubleValue = Double(rightPinch)
        leftGrabIndicator.doubleValue = Double(leftGrab)
        rightGrabIndicator.doubleValue = Double(rightGrab)

        leftPinchAmountTextField.stringValue = String(format: "%.2f", leftPinch)
        rightPinchAmountTextField.stringValue = String(format: "%.2f", rightPinch)
        leftGrabAmountTextField.stringValue = String(format: "%.2f", leftGrab)
        rightGrabAmountTextField.stringValue = String(format: "%.2f", rightGrab)
        
        // TODO: hightlight the image indicators in a nice way when pinching/grabbing)

        leftPinchImage.layer?.backgroundColor = (leftState.isPinching ? NSColor.systemBlue : NSColor.clear).cgColor
        rightPinchImage.layer?.backgroundColor = (rightState.isPinching ? NSColor.systemRed : NSColor.clear).cgColor
        leftGrabImage.layer?.backgroundColor = (leftState.isGrabbing ? NSColor.systemBlue : NSColor.clear).cgColor
        rightGrabImage.layer?.backgroundColor = (rightState.isGrabbing ? NSColor.systemRed : NSColor.clear).cgColor

        if let cgImage = store.cameraImage, !cameraImageView.isHidden {
            cameraImageView.image = nil
            cameraImageView.layer?.contents = cgImage
        } else if cameraImageView.isHidden {
            cameraImageView.layer?.contents = nil
        } else {
            cameraImageView.layer?.contents = nil
            cameraImageView.image = NSImage(named: "AppIcon")
        }
    }

    @MainActor
    private func showDisconnectedUI() {
        cameraImageView.layer?.contents = nil
        cameraImageView.image = NSImage(systemSymbolName: "video", accessibilityDescription: "No camera connected")
        hideImageView()
    }

    // MARK: - UI controls

    private func hideImageView() {
        cameraImageView.isHidden = true
        toggleImageViewSwitch.state = .off
    }

    private func showImageView() {
        cameraImageView.isHidden = false
        toggleImageViewSwitch.state = .on
    }

    private func toggleStatsView() {
        view.isHidden.toggle()
        toggleStatsViewSwitch.state = view.isHidden ? .off : .on
    }

    // Detect each keyboard event
    private func myKeyDownEvent(event: NSEvent) -> NSEvent {
        if event.specialKey == .tab {
            toggleStatsView()
        }
        return event
    }

    @IBAction func HandleStatsSwitchChanged(_ sender: NSSwitch) {
        view.isHidden = (sender.state == .off)
    }

    @IBAction func HandleImageSwitchChanged(_ sender: NSSwitch) {
        if sender.state == .on { showImageView() } else { hideImageView() }
    }

    deinit {
        if let keyBoardMonitor {
            NSEvent.removeMonitor(keyBoardMonitor)
        }
        cancellables.removeAll()
    }
}
