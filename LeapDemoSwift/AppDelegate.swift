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
    @IBOutlet weak var sceneKitView: SCNView!
    
    var leftHandSphere : SCNNode!
    var rightHandSphere : SCNNode!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let scene = GameScene(fileNamed:"GameScene") {
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .aspectFill
            
            self.skView!.presentScene(scene)
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            self.skView!.ignoresSiblingOrder = true
            
            self.skView!.showsFPS = true
            self.skView!.showsNodeCount = true        }
        
        sceneKitView.scene = makeScene()
        sceneKitView.allowsCameraControl = true
        
//        let sphereGeometry = SCNSphere(radius: 10)
//        let sphereNode = SCNNode(geometry: sphereGeometry)
//        sceneKitView.scene?.rootNode.addChildNode(sphereNode)
//    
//        sceneKitView.scene?.rootNode.addChildNode(node)
        
        addHandSpheres()
    }
    
    func makeScene() -> SCNScene? {
      let scene = SCNScene(named: "Hand3DScene.scn")
      return scene
    }
    
    func setUpCamera() -> SCNNode? {
      let cameraNode = sceneKitView?.scene?.rootNode
        .childNode(withName: "camera", recursively: false)
      return cameraNode
    }
    
    func addTestCube(){
        let imageMaterial = SCNMaterial()
        imageMaterial.isDoubleSided = false
        imageMaterial.diffuse.contents = NSImage(named: "leftHand")
        let cube: SCNGeometry? = SCNBox(width: 1.0, height: 1.0, length: 1, chamferRadius: 0)
        let node = SCNNode(geometry: cube)
        node.geometry?.materials = [imageMaterial]
    }
    
    func addHandSpheres()  {
        let sphereGeometry = SCNSphere(radius: 0.01)
        leftHandSphere = SCNNode(geometry: sphereGeometry)
        leftHandSphere.position = SCNVector3(x: -0.1, y: 0, z: 0)
        sceneKitView.scene?.rootNode.addChildNode(leftHandSphere)
        
        rightHandSphere = SCNNode(geometry: sphereGeometry)
        leftHandSphere.position = SCNVector3(x: 0.1, y: 0, z: 0)
        sceneKitView.scene?.rootNode.addChildNode(rightHandSphere)
    }
    

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

