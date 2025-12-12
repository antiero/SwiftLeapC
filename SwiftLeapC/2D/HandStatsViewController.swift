//
//  HandStats.swift
//  Ultraleap
//
//  Created by Ant Nasce on 27/07/2023.
//  Copyright © 2023 Antony Nasce. All rights reserved.
//

import Foundation
import AppKit

class HandStatsViewController : NSViewController {
    
    var keyBoardMonitor: Any?
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
    @IBOutlet weak var cameraImageView: NSImageView!
    @IBOutlet weak var rightGrabAmountTextField: NSTextField!
    let pinchDetector = LeapPinchDetector()
    let handManager = LeapHandManager.sharedInstance
    @IBOutlet weak var toggleStatsViewSwitch: NSSwitch!
    @IBOutlet weak var toggleImageViewSwitch: NSSwitch!
    
    // Coalesce high-frequency Leap notifications into a single UI update on the main thread.
    private let uiUpdateLock = NSLock()
    private var uiUpdateScheduled = false
    private var didRegisterObservers = false
    
    func initLeapStats(){
        if didRegisterObservers { return }
        didRegisterObservers = true
        leftPinchIndicator.warningValue = pinchDetector.pinchThreshold
        rightPinchIndicator.warningValue = pinchDetector.pinchThreshold
        leftGrabIndicator.warningValue = pinchDetector.grabThreshold
        rightGrabIndicator.warningValue = pinchDetector.grabThreshold
        
        // Render camera frames via CALayer contents (CGImage) to avoid NSImage snapshot churn.
        cameraImageView.wantsLayer = true
        cameraImageView.layer?.contentsGravity = .resizeAspect
        NotificationCenter.default.addObserver(self, selector: #selector(updateHandStats), name: LeapHandManager.OnNewLeapFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDisconnected), name: LeapHandManager.OnDisconnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOnPinchBegan), name: LeapPinchDetector.OnPinchBegan, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOnPinchEnded), name: LeapPinchDetector.OnPinchEnded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOnGrabBegan), name: LeapPinchDetector.OnGrabBegan, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOnGrabEnded), name: LeapPinchDetector.OnGrabEnded, object: nil)
        
        self.keyBoardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: myKeyDownEvent)
        
        // Initially hide the image preview
        hideImageView()
    }
    
    @objc private func handleOnPinchBegan(_ notification: Notification){
        guard let item = notification.object as? LEAP_HAND else {
            return
        }
        
        if (item.type == eLeapHandType_Left){
            //print("LEFT PINCH BEGAN!")
        }
        else {
            //print("RIGHT PINCH BEGAN!")
        }
    }
    
    @objc private func handleOnGrabBegan(_ notification: Notification){
        guard let item = notification.object as? LEAP_HAND else {
            return
        }
        
        if (item.type == eLeapHandType_Left){
            DispatchQueue.main.async {
                self.leftGrabImage.image?.backgroundColor = NSColor.blue
            }
            
        }
        else {
            DispatchQueue.main.async {
                self.rightGrabImage.image?.backgroundColor = NSColor.blue
            }
        }
    }
    
    
    @objc private func handleOnPinchEnded(_ notification: Notification){
        guard let item = notification.object as? LEAP_HAND else {
            return
        }
        
        if (item.type == eLeapHandType_Left){
            //print("LEFT PINCH ENDED!")
            DispatchQueue.main.async {
                self.leftPinchImage.image?.backgroundColor = NSColor.white
            }
        }
        else {
            DispatchQueue.main.async {
                self.rightPinchImage.image?.backgroundColor = NSColor.white
            }
        }
    }
    
    @objc private func handleOnGrabEnded(_ notification: Notification){
        guard let item = notification.object as? LEAP_HAND else {
            return
        }
        
        if (item.type == eLeapHandType_Left){
            //print("LEFT GRAb ENDED!")
        }
        else {
            //print("RIGHT GRAB ENDED!")
        }
    }
    
    @objc private
    func updateHandStats(_ notification: Notification){
        // Called from the Leap pump thread via NotificationCenter.
        // Coalesce to avoid unbounded main-queue backlog when app is backgrounded.
        scheduleUIUpdate()
    }
    
    private func scheduleUIUpdate() {
        uiUpdateLock.lock()
        if uiUpdateScheduled {
            uiUpdateLock.unlock()
            return
        }
        uiUpdateScheduled = true
        uiUpdateLock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.uiUpdateLock.lock()
            self.uiUpdateScheduled = false
            self.uiUpdateLock.unlock()
            
            self.performUIUpdate()
        }
    }
    
    @MainActor
    private func performUIUpdate() {
        
        DispatchQueue.main.async {
            // Don't bother to update if the view is not shown...
            if (self.view.isHidden){
                return
            }
            
            self.pinchDetector.updatePinchStates()
            let leftPinchAmount = self.pinchDetector.pinchStrength(hand: self.handManager.leftHand)
            let rightPinchAmount = self.pinchDetector.pinchStrength(hand: self.handManager.rightHand)
            let leftGrabAmount = self.pinchDetector.grabStrength(hand: self.handManager.leftHand)
            let rightGrabAmount = self.pinchDetector.grabStrength(hand: self.handManager.rightHand)
            
            
            self.leftPinchAmountTextField.stringValue = String(format: "%.2f", leftPinchAmount)
            self.leftGrabAmountTextField.stringValue = String(format: "%.2f", leftGrabAmount)
            self.rightPinchAmountTextField.stringValue = String(format: "%.2f", rightPinchAmount)
            self.rightGrabAmountTextField.stringValue = String(format: "%.2f", rightGrabAmount)
            
            self.leftPinchIndicator.floatValue = Float(leftPinchAmount)
            self.rightPinchIndicator.floatValue = Float(rightPinchAmount)
            self.leftGrabIndicator.floatValue = Float(leftGrabAmount)
            self.rightGrabIndicator.floatValue = Float(rightGrabAmount)
            
            if let cgImage = self.handManager.getCurrentImageThreadSafe() {
                self.cameraImageView.image = nil
                self.cameraImageView.layer?.contents = cgImage
            }
            else{
                self.cameraImageView.layer?.contents = nil
                self.cameraImageView.image = NSImage(named: "AppIcon")
            }
        }
    }
    
    @objc private func handleDisconnected(_ notification: Notification){
        DispatchQueue.main.async {
            self.cameraImageView.image = NSImage(systemSymbolName: "video", accessibilityDescription: "No camera connected")
            self.hideImageView()
        }
    }
    
    @IBAction func HandleStatsSwitchChanged(_ sender: NSSwitch) {
        self.view.isHidden = (sender.state == .off)
    }
    
    func toggleStatsView(){
        self.view.isHidden = !self.view.isHidden
        toggleStatsViewSwitch.state = (self.view.isHidden ? .off : .on)
    }
    
    func toggleImageView(){
        self.cameraImageView.isHidden = !self.cameraImageView.isHidden
        toggleImageViewSwitch.state = (self.cameraImageView.isHidden ? .off : .on)
    }
    
    @IBAction func HandleImageSwitchChanged(_ sender: NSSwitch) {
        toggleImageView()
    }
    
    func hideImageView(){
        self.cameraImageView.isHidden = true
        toggleImageViewSwitch.state = .off
    }
    
    // Detect each keyboard event
    func myKeyDownEvent(event: NSEvent) -> NSEvent {
        // keyCode 36 is for detect RETURN/ENTER
        if event.specialKey == NSEvent.SpecialKey.tab {
            toggleStatsView()
        }
        return event
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
