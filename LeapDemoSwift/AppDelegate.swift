//
//  AppDelegate.swift
//  LeapDemoSwift
//
//  Created by Kelly Innes on 10/24/15.
//  Copyright © 2015 Kelly Innes. All rights reserved.
//

import Cocoa
import SpriteKit
import SceneKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var skView: SKView!
    @IBOutlet weak var handPreview: SCNView!
    var handPreviewController = HandPreviewViewController()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        if let scene = GameScene(fileNamed:"GameScene") {
//            /* Set the scale mode to scale to fit the window */
//            scene.scaleMode = .aspectFill
//            
//            self.skView!.presentScene(scene)
//            
//            /* Sprite Kit applies additional optimizations to improve rendering performance */
//            self.skView!.ignoresSiblingOrder = true
//            
//            self.skView!.showsFPS = true
//            self.skView!.showsNodeCount = true        }

        handPreview.scene = handPreviewController.makeScene()
        handPreview.delegate = handPreviewController
        handPreview.isPlaying = true
        handPreview.allowsCameraControl = true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

