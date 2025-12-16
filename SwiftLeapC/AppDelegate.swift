//
//  AppDelegate.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 01/07/2025.

import Cocoa
import SpriteKit
import SceneKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var handPreviewController: HandPreviewViewController!
    @IBOutlet weak var handStatsView: HandStatsViewController!
    @IBOutlet weak var cameraFeedViewController: CameraFeedViewController!

    private var statusItem: NSStatusItem!
    lazy var showHideMenuItem: NSMenuItem = {
        NSMenuItem(title: "Hide",
                   action: #selector(ToggleWindow),
                   keyEquivalent: "")
    }()

            
    func applicationDidFinishLaunching(_ notification: Notification) {
        LeapTrackingCoordinator.shared.start(enableImages: true)
        
        Task { @MainActor in
            HandTrackingStore.shared.start(session: LeapSession.shared)
            print("Called HandTrackingStore.shared.start(session: LeapSession.shared)")
        }
        
        // Force the SCNView to load so viewDidLoad runs and hooks up the delegate
        _ = handPreviewController.view
        
        handStatsView.initLeapStats()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "ultraleap-icon-menubar")
        }
        setupMenus()
        
        window.canHide = true
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func ToggleWindow() {
        window.setIsVisible(!window.isVisible)
        showHideMenuItem.title = (window.isMainWindow) ? "Hide" : "Show"
    }

    func setupMenus() {
        let menu = NSMenu()
        menu.addItem(showHideMenuItem)
        menu.addItem(NSMenuItem(title: "Quit",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
    }
}
