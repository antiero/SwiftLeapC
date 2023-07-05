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
    
    let PALM_BALL_RADIUS : CGFloat = 0.012
    let SPHERE_RADIUS : CGFloat = 0.008
    let TOTAL_JOINT_COUNT : Int = 4 * 5;
    
    var leftSpherePositions : [SCNVector3] = [SCNVector3]()
    var leftHandNodes : [SCNNode] = [SCNNode]()
    var leftHandBoneNodes : [SCNNode] = [SCNNode]()
    
    var rightSpherePositions : [SCNVector3] = [SCNVector3]()
    var rightHandNodes : [SCNNode] = [SCNNode]()
    var rightHandBoneNodes : [SCNNode] = [SCNNode]()
    
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
        let sphereGeoLeft = SCNSphere(radius: PALM_BALL_RADIUS)
        let leftMaterial = SCNMaterial()
        leftMaterial.diffuse.contents = NSColor.blue
        leftMaterial.normal.intensity = 1.0
        leftMaterial.diffuse.intensity = 1.0

        
        let sphereGeoRight = SCNSphere(radius: PALM_BALL_RADIUS)
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
        if let digits = leftHand?.digits {
            let thumb = digits.0
            let index = digits.1
            let middle = digits.2
            let ring = digits.3
            let pinky = digits.4
            let fingers = [thumb, index, middle, ring, pinky]
            for fingerIx in 0...4 {
                let finger = fingers[fingerIx]
                let bones = [finger.bones.0, finger.bones.1, finger.bones.2, finger.bones.3]
                for jointIx in 0...3
                {
                    let index = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
                    let position = bones[jointIx].next_joint
                    let vec3 = SCNVector3(0.001*position.x, 0.001*position.y, 0.001*position.z)
                    leftSpherePositions[index] = vec3
                    UpdateSphereNodeWithPosition(node: leftHandNodes[index], position: vec3)
                }
            }
        }
        else{
            return;
        }
        
        var leftBoneIndex = 0
        //Draw cylinders between left finger joints
        for fingerIx in 0...4
        {
            for jointIx in 0...2
            {
                let keyA = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx);
                let keyB = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx + 1);
                leftHandBoneNodes[leftBoneIndex] = leftHandBoneNodes[leftBoneIndex].buildLineInTwoPointsWithRotation(
                    from: leftSpherePositions[keyA],
                    to: leftSpherePositions[keyB],
                    radius: SPHERE_RADIUS, color: .white)
                leftBoneIndex += 1
            }
        }
    }
    
    func UpdateRightHandBonePositions(){
        if (handManager.rightHand == nil){
            return
        }
        
        let leftHand = handManager.rightHand
        if let digits = leftHand?.digits {
            let thumb = digits.0
            let index = digits.1
            let middle = digits.2
            let ring = digits.3
            let pinky = digits.4
            let fingers = [thumb, index, middle, ring, pinky]
            for fingerIx in 0...4 {
                let finger = fingers[fingerIx]
                let bones = [finger.bones.0, finger.bones.1, finger.bones.2, finger.bones.3]
                for jointIx in 0...3
                {
                    let index = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
                    let position = bones[jointIx].next_joint
                    let vec3 = SCNVector3(0.001*position.x, 0.001*position.y, 0.001*position.z)
                    rightSpherePositions[index] = vec3
                    UpdateSphereNodeWithPosition(node: rightHandNodes[index], position: vec3)
                }
            }
        }
        else{
            return;
        }
        
        var rightBoneIndex = 0
        //Draw cylinders between left finger joints
        for fingerIx in 0...4
        {
            for jointIx in 0...2
            {
                let keyA = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx);
                let keyB = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx + 1);
                rightHandBoneNodes[rightBoneIndex] = rightHandBoneNodes[rightBoneIndex].buildLineInTwoPointsWithRotation(
                    from: rightSpherePositions[keyA],
                    to: rightSpherePositions[keyB],
                    radius: SPHERE_RADIUS, color: .white)
                rightBoneIndex += 1
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
        leftSpherePositions = [SCNVector3](repeating: SCNVector3(), count: TOTAL_JOINT_COUNT)
        rightSpherePositions = [SCNVector3](repeating: SCNVector3(), count: TOTAL_JOINT_COUNT)
        
        print("InitialiseLeftHandSpheres")
        let sphereGeoLeft = SCNSphere(radius: CGFloat(SPHERE_RADIUS))
        let leftMaterial = SCNMaterial()
        leftMaterial.diffuse.contents = NSColor.blue
        leftMaterial.normal.intensity = 1.0
        leftMaterial.diffuse.intensity = 1.0
        
        let sphereGeoRight = SCNSphere(radius: CGFloat(SPHERE_RADIUS))
        let rightMaterial = SCNMaterial()
        rightMaterial.diffuse.contents = NSColor.red
        rightMaterial.normal.intensity = 1.0
        rightMaterial.diffuse.intensity = 1.0
        
        for nodeIx in 0...19{
            let sphere = SCNNode(geometry: sphereGeoLeft)
            sphere.geometry?.materials = [leftMaterial]
            leftHandNodes.append(sphere)
            scene?.rootNode.addChildNode(leftHandNodes[nodeIx])
        }
        
        // Initialise Left Hand Bone Cylinders
        for boneIx in 0...24 {
            let newBone = SCNNode()
            leftHandBoneNodes.append(newBone)
            scene.rootNode.addChildNode(
                leftHandBoneNodes[boneIx].buildLineInTwoPointsWithRotation(
                    from: SCNVector3(0.01,-0.01,0.03),
                    to: SCNVector3(0.07,0.011,0.07),
                    radius: SPHERE_RADIUS*0.8, color: .white))
        }
        // Initialise Right Hand Bone Cylinders
        for boneIx in 0...24 {
            let newBone = SCNNode()
            rightHandBoneNodes.append(newBone)
            scene.rootNode.addChildNode(
                rightHandBoneNodes[boneIx].buildLineInTwoPointsWithRotation(
                    from: SCNVector3(0.01,-0.01,0.03),
                    to: SCNVector3(0.07,0.011,0.07),
                    radius: SPHERE_RADIUS*0.8, color: .white))
        }
        
        for nodeIx in 0...19{
            let sphere = SCNNode(geometry: sphereGeoRight)
            sphere.geometry?.materials = [rightMaterial]
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
