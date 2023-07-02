//
//  HandPreviewViewController.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 01/07/2023.
//  Copyright © 2023 Kelly Innes. All rights reserved.
//

import Foundation
import SwiftUI
import SceneKit

class HandPreviewViewController : NSObject, SCNSceneRendererDelegate {
    var leftHandSphere : SCNNode!
    var rightHandSphere : SCNNode!
    let handManager = LeapHandManager.sharedInstance
    var scene : SCNScene! = nil
    
    let SPHERE_RADIUS : Float = 0.01
    let TOTAL_JOINT_COUNT : Int = 4 * 5;
    let sphereMesh = SCNSphere(radius: 0.01)
    let cylinderMesh = SCNCylinder(radius: 0.01, height: 0.04)
    let palmRadius : Float = 0.015
    
    var leftHandNodes : [SCNNode] = [SCNNode]()
    var rightHandNodes : [SCNNode] = [SCNNode]()
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateHandPositions()
    }
    
    func initialiseScene() -> SCNScene? {
        scene = makeScene();
        return scene
    }
    
    func makeScene() -> SCNScene? {
        scene = SCNScene(named: "Hand3DScene.scn")
        addHandSpheres();
        return scene
    }
    
    func addHandSpheres()  {
        let sphereGeoLeft = SCNSphere(radius: 0.015)
        let leftMaterial = SCNMaterial()
        leftMaterial.diffuse.contents = NSColor.blue
        leftMaterial.normal.intensity = 1.0
        leftMaterial.diffuse.intensity = 1.0

        
        let sphereGeoRight = SCNSphere(radius: 0.015)
        let rightMaterial = SCNMaterial()
        rightMaterial.diffuse.contents = NSColor.red
        rightMaterial.normal.intensity = 1.0
        rightMaterial.diffuse.intensity = 1.0
        
        leftHandSphere = SCNNode(geometry: sphereGeoLeft)
        leftHandSphere.geometry?.materials = [leftMaterial]
        leftHandSphere.position = SCNVector3(x: -0.1, y: 0, z: 0)
        leftHandSphere.name = "LEFT"
        scene?.rootNode.addChildNode(leftHandSphere)
        
        rightHandSphere = SCNNode(geometry: sphereGeoRight)
        rightHandSphere.geometry?.materials = [rightMaterial]
        rightHandSphere.position = SCNVector3(x: 0.1, y: 0, z: 0)
        rightHandSphere.name = "RIGHT"
        scene?.rootNode.addChildNode(rightHandSphere)
        
        InitialiseHandSpheres()
    }
    
    func getFingerJointIndex(fingerIndex: Int, jointIndex: Int) -> Int
    {
        return fingerIndex * 4 + jointIndex;
    }
    
    func UpdateLeftHandBonePositions(){
        if (handManager.leftHand == nil){
            return
        }
        
        let leftHand = handManager.leftHand
        let digits = leftHand?.digits
        let thumb = digits!.0
        let index = digits!.1
        let middle = digits!.2
        let ring = digits!.3
        let pinky = digits!.4
        let fingers = [thumb, index, middle, ring, pinky]
        for fingerIx in 0...4 {
            let finger = fingers[fingerIx]
            let bones = [finger.bones.0, finger.bones.1, finger.bones.2, finger.bones.3]
            for jointIx in 0...3
            {
                let index = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
                //print("Bone index: ", index)
                let position = bones[jointIx].next_joint
                let vec3 = SCNVector3(0.001*position.x, 0.001*position.y, 0.001*position.z)
                //spherePositions.append(vec3)
                UpdateSphereNodeWithPosition(node: leftHandNodes[index], position: vec3)
                //print("LEFT NODE COUNT: ", leftHandNodes.count)
            }
        }
    }
    
    func UpdateRightHandBonePositions(){
        if (handManager.rightHand == nil){
            return
        }
        
        let hand = handManager.rightHand
        let digits = hand?.digits
        let thumb = digits!.0
        let index = digits!.1
        let middle = digits!.2
        let ring = digits!.3
        let pinky = digits!.4
        let fingers = [thumb, index, middle, ring, pinky]
        for fingerIx in 0...4 {
            let finger = fingers[fingerIx]
            let bones = [finger.bones.0, finger.bones.1, finger.bones.2, finger.bones.3]
            for jointIx in 0...3
            {
                let index = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
                let position = bones[jointIx].next_joint
                let vec3 = SCNVector3(0.001*position.x, 0.001*position.y, 0.001*position.z)
                UpdateSphereNodeWithPosition(node: rightHandNodes[index], position: vec3)
            }
        }
    }
    
    
    func UpdateSphereNodeWithPosition(node : SCNNode, position : SCNVector3){
        if (node != nil){
            //print("Updating Position: ", position)
            node.position = position
        }
    }
    
    func InitialiseHandSpheres()
    {
        print("InitialiseLeftHandSpheres")
        let sphereGeometry = SCNSphere(radius: CGFloat(SPHERE_RADIUS))
        for nodeIx in 0...19{
            let sphere = SCNNode(geometry: sphereGeometry)
            leftHandNodes.append(sphere)
            scene?.rootNode.addChildNode(leftHandNodes[nodeIx])
        }
        
        for nodeIx in 0...19{
            let sphere = SCNNode(geometry: sphereGeometry)
            rightHandNodes.append(sphere)
            scene?.rootNode.addChildNode(rightHandNodes[nodeIx])
        }
    }
    
    func updateHandPositions() {
        rightLoop: if (handManager.rightHandPresent()){
            if (handManager.rightHand == nil){
                break rightLoop
            }
            if let newRightHandPosition = handManager.rightHandPosition {
                rightHandSphere.position = handManager.rightPalmPosAsSCNVector3()
                UpdateRightHandBonePositions()
            }
        }
            
        leftLoop: if (handManager.leftHandPresent()){
            if (handManager.leftHand == nil){
                break leftLoop
            }
            if let newLeftHandPosition = handManager.leftHandPosition {
                leftHandSphere.position = handManager.leftPalmPosAsSCNVector3()
                UpdateLeftHandBonePositions()
            }
        }
    }
}
