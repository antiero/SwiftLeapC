//
//  AppDelegate.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 01/07/2023.

import Cocoa
import SpriteKit
import SceneKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    @IBOutlet weak var window: NSWindow!
    lazy var showHideMenuItem : NSMenuItem = {
       return NSMenuItem(title: "Hide", action: #selector(ToggleWindow), keyEquivalent: "")
    }()
    @IBOutlet weak var handPreviewController : HandPreviewViewController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        handPreviewController.initialiseScene()
        // 2
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // 3
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
        // 1
        let menu = NSMenu()
        
        // 2
        //let one = NSMenuItem(title: showHideMenuItem.title, action: #selector(ToggleWindow), keyEquivalent: "")
        menu.addItem(showHideMenuItem)
        
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // 3
        statusItem.menu = menu
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

