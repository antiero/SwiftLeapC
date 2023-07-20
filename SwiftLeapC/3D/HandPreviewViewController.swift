//
//  HandPreviewViewController.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 01/07/2023.
//

import Foundation
import SwiftUI
import SceneKit

class HandPreviewViewController : NSObject, SCNSceneRendererDelegate {
    var leftHand : SCNNode!
    var leftHandSphere : SCNNode!
    var leftPinkyMetacarpelSphere : SCNNode!
    
    
    var rightHand : SCNNode!
    var rightHandSphere : SCNNode!
    var rightPinkyMetacarpelSphere : SCNNode!
    let handManager = LeapHandManager.sharedInstance
    var scene : SCNScene! = nil
    
    let joinThumbProximal : Bool = true
    let joinFingerProximals : Bool = true
    let showPinkyMetacarpal : Bool = true
    let PALM_BALL_RADIUS : CGFloat = 0.012
    let SPHERE_RADIUS : CGFloat = 0.008
    let TOTAL_JOINT_COUNT : Int = 4 * 5;
    let PINKY_BASE_INDEX = 16;
    
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
        
        // The root left/right hand objects
        leftHand = SCNNode()
        leftHand.name = "LeftHand"
        rightHand = SCNNode()
        rightHand.name = "RightHand"
        scene?.rootNode.addChildNode(leftHand)
        scene?.rootNode.addChildNode(rightHand)
        
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
        leftHandSphere.position = SCNVector3(x: 1, y: 1, z: 1)
        leftHandSphere.name = "LEFT"
        leftHand.addChildNode(leftHandSphere)
        
        rightHandSphere = SCNNode(geometry: sphereGeoRight)
        rightHandSphere.geometry?.materials = [rightMaterial]
        rightHandSphere.position = SCNVector3(x: 1, y: 1, z: 1)
        rightHandSphere.name = "RIGHT"
        rightHand.addChildNode(rightHandSphere)
        
        InitialiseHandGeo()
    }
    
    func getFingerJointIndex(fingerIndex: Int, jointIndex: Int) -> Int
    {
        return fingerIndex * 4 + jointIndex;
    }
    
    func UpdateLeftHandBonePositions(){
        if (handManager.leftHand == nil){
            return
        }
        leftHandSphere.position = handManager.leftPalmPosAsSCNVector3()
        let hand = handManager.leftHand
        if let digits = hand?.digits {
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
            
            var leftBoneIndex = 0
            //Draw cylinders between left finger joints
            for fingerIx in 0...4
            {
                for jointIx in 0...2
                {
                    let keyA = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx);
                    let keyB = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx + 1);
                    UpdateLeftCylinderBoneAtIndex(leftBoneIndex: leftBoneIndex, keyA: keyA, keyB: keyB)
                    leftBoneIndex += 1
                }
            }
            
            // Draw cylinder between thumb and index finger
            if (joinThumbProximal)
            {
                let keyA = getFingerJointIndex(fingerIndex: 0, jointIndex: 0);
                let keyB = getFingerJointIndex(fingerIndex: 1, jointIndex: 0);
                UpdateLeftCylinderBoneAtIndex(leftBoneIndex: leftBoneIndex, keyA: keyA, keyB: keyB)
                leftBoneIndex += 1
            }
            
            if (joinFingerProximals)
            {
                for i in 1...3
                {
                    let keyA = getFingerJointIndex(fingerIndex: i, jointIndex: 0);
                    let keyB = getFingerJointIndex(fingerIndex: i + 1, jointIndex: 0);
                    UpdateLeftCylinderBoneAtIndex(leftBoneIndex: leftBoneIndex, keyA: keyA, keyB: keyB)
                    leftBoneIndex += 1
                }
            }
            
            if (showPinkyMetacarpal){
                
                let pinkyMetacarpal = pinky.metacarpal.prev_joint
                //let indexMetacarpal = index.metacarpal.prev_joint // THIS DID NOT LOOK RIGHT, USE THUMB!
                let indexMetacarpal = thumb.metacarpal.prev_joint
                let vecA = SCNVector3(0.001*pinkyMetacarpal.x, 0.001*pinkyMetacarpal.y, 0.001*pinkyMetacarpal.z)
                let vecB = SCNVector3(0.001*indexMetacarpal.x, 0.001*indexMetacarpal.y, 0.001*indexMetacarpal.z)
                
                SetNodePositionFromLeapVector(node: leftPinkyMetacarpelSphere, vec: pinkyMetacarpal)
                leftHandBoneNodes[leftBoneIndex] = UpdateCylinderBoneAtIndex(nodeIn: leftHandBoneNodes[leftBoneIndex],
                                          vecA: vecA, vecB: vecB)
                leftBoneIndex += 1
                leftHandBoneNodes[leftBoneIndex] = UpdateCylinderBoneAtIndex(nodeIn: leftHandBoneNodes[leftBoneIndex],
                                          vecA: vecA, vecB: leftSpherePositions[PINKY_BASE_INDEX])
            }

        }
    }
    
    func UpdateLeftCylinderBoneAtIndex(leftBoneIndex: Int, keyA: Int, keyB: Int){
        leftHandBoneNodes[leftBoneIndex] = leftHandBoneNodes[leftBoneIndex].buildLineInTwoPointsWithRotation(
            from: leftSpherePositions[keyA],
            to: leftSpherePositions[keyB],
            radius: SPHERE_RADIUS, color: .white)
    }
    
    func UpdateRightCylinderBoneAtIndex(rightBoneIndex: Int, keyA: Int, keyB: Int){
        rightHandBoneNodes[rightBoneIndex] = rightHandBoneNodes[rightBoneIndex].buildLineInTwoPointsWithRotation(
            from: rightSpherePositions[keyA],
            to: rightSpherePositions[keyB],
            radius: SPHERE_RADIUS, color: .white)
    }
    
    func UpdateCylinderBoneAtIndex(nodeIn: SCNNode, vecA: SCNVector3, vecB: SCNVector3) -> SCNNode {
        let nodeOut = nodeIn.buildLineInTwoPointsWithRotation(
            from: vecA,
            to: vecB,
            radius: SPHERE_RADIUS, color: .white)
        return nodeOut
    }
    
    func SetNodePositionFromLeapVector(node : SCNNode, vec : LEAP_VECTOR){
        let newPos = SCNVector3(0.001*vec.x, 0.001*vec.y, 0.001*vec.z)
        node.position = newPos
    }
    
    func UpdateRightHandBonePositions(){
        if (handManager.rightHand == nil){
            return
        }
        rightHandSphere.position = handManager.rightPalmPosAsSCNVector3()
        let hand = handManager.rightHand
        if let digits = hand?.digits {
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
            
            var rightBoneIndex = 0
            //Draw cylinders between left finger joints
            for fingerIx in 0...4
            {
                for jointIx in 0...2
                {
                    let keyA = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx);
                    let keyB = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx + 1);
                    UpdateRightCylinderBoneAtIndex(rightBoneIndex: rightBoneIndex, keyA: keyA, keyB: keyB)
                    rightBoneIndex += 1
                }
            }
            
            // Draw cylinder between thumb and index finger
            if (joinThumbProximal)
            {
                let keyA = getFingerJointIndex(fingerIndex: 0, jointIndex: 0);
                let keyB = getFingerJointIndex(fingerIndex: 1, jointIndex: 0);
                UpdateRightCylinderBoneAtIndex(rightBoneIndex: rightBoneIndex, keyA: keyA, keyB: keyB)
                rightBoneIndex += 1
            }
            
            if (joinFingerProximals)
            {
                for i in 1...3
                {
                    let keyA = getFingerJointIndex(fingerIndex: i, jointIndex: 0);
                    let keyB = getFingerJointIndex(fingerIndex: i + 1, jointIndex: 0);
                    UpdateRightCylinderBoneAtIndex(rightBoneIndex: rightBoneIndex, keyA: keyA, keyB: keyB)
                    rightBoneIndex += 1
                }
            }
            
            if (showPinkyMetacarpal){
                
                let pinkyMetacarpal = pinky.metacarpal.prev_joint
                //let indexMetacarpal = index.metacarpal.prev_joint // THIS DID NOT LOOK RIGHT, USE THUMB!
                let indexMetacarpal = thumb.metacarpal.prev_joint
                let vecA = SCNVector3(0.001*pinkyMetacarpal.x, 0.001*pinkyMetacarpal.y, 0.001*pinkyMetacarpal.z)
                let vecB = SCNVector3(0.001*indexMetacarpal.x, 0.001*indexMetacarpal.y, 0.001*indexMetacarpal.z)
                
                SetNodePositionFromLeapVector(node: rightPinkyMetacarpelSphere, vec: pinkyMetacarpal)
                rightHandBoneNodes[rightBoneIndex] = UpdateCylinderBoneAtIndex(nodeIn: rightHandBoneNodes[rightBoneIndex],
                                          vecA: vecA, vecB: vecB)
                rightBoneIndex += 1
                rightHandBoneNodes[rightBoneIndex] = UpdateCylinderBoneAtIndex(nodeIn: rightHandBoneNodes[rightBoneIndex],
                                          vecA: vecA, vecB: rightSpherePositions[PINKY_BASE_INDEX])
            }
        }
    }
    
    
    func UpdateSphereNodeWithPosition(node : SCNNode, position : SCNVector3){
        node.position = position
    }
    
    func InitialiseHandGeo()
    {
        leftSpherePositions = [SCNVector3](repeating: SCNVector3(), count: TOTAL_JOINT_COUNT)
        rightSpherePositions = [SCNVector3](repeating: SCNVector3(), count: TOTAL_JOINT_COUNT)
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
        
        // Left Hand Sphere Joints
        for nodeIx in 0...19{
            let sphere = SCNNode(geometry: sphereGeoLeft)
            sphere.geometry?.materials = [leftMaterial]
            sphere.name = "LeftSphere-\(nodeIx)"
            leftHandNodes.append(sphere)
            leftHand.addChildNode(leftHandNodes[nodeIx])
        }
        
        // Initialise Left Hand Bone Cylinders
        for boneIx in 0...20 {
            let newBone = SCNNode()
            newBone.name = "LeftBone-\(boneIx)"
            leftHandBoneNodes.append(newBone)
            leftHand.addChildNode(
                leftHandBoneNodes[boneIx].buildLineInTwoPointsWithRotation(
                    from: SCNVector3(1,1,1),
                    to: SCNVector3(1,1,1),
                    radius: SPHERE_RADIUS*0.8, color: .white))
        }
        
        // Also do those pinky ball joints..
        leftPinkyMetacarpelSphere = SCNNode(geometry: sphereGeoLeft)
        leftPinkyMetacarpelSphere.geometry?.materials = [leftMaterial]
        leftPinkyMetacarpelSphere.position = SCNVector3(x: 1, y: 1, z: 1)
        leftPinkyMetacarpelSphere.name = "LEFTPINKYMETA"
        leftHand.addChildNode(leftPinkyMetacarpelSphere)
        
        // Right Hand Sphere Joints
        for nodeIx in 0...19{
            let sphere = SCNNode(geometry: sphereGeoRight)
            sphere.geometry?.materials = [rightMaterial]
            rightHandNodes.append(sphere)
            rightHand.addChildNode(rightHandNodes[nodeIx])
        }

        // Initialise Right Hand Bone Cylinders
        for boneIx in 0...20 {
            let newBone = SCNNode()
            newBone.name = "RightBone-\(boneIx)"
            rightHandBoneNodes.append(newBone)
            rightHand.addChildNode(
                rightHandBoneNodes[boneIx].buildLineInTwoPointsWithRotation(
                    from: SCNVector3(1,1,1),
                    to: SCNVector3(1,1,1),
                    radius: SPHERE_RADIUS*0.8, color: .white))
        }
        
        // Also do those pinky ball joints..
        rightPinkyMetacarpelSphere = SCNNode(geometry: sphereGeoRight)
        rightPinkyMetacarpelSphere.geometry?.materials = [rightMaterial]
        rightPinkyMetacarpelSphere.position = SCNVector3(x: 1, y: 1, z: 1)
        rightPinkyMetacarpelSphere.name = "RIGHTPINKYMETA"
        rightHand.addChildNode(rightPinkyMetacarpelSphere)
        
    }
    
    func updateHandPositions() {

        if handManager.rightHandPresent() {
            rightHand.isHidden = false
            UpdateRightHandBonePositions()
        }
        else{
            rightHand.isHidden = true
        }
        
        if handManager.leftHandPresent() {
            leftHand.isHidden = false
            UpdateLeftHandBonePositions()
        }
        else{
            leftHand.isHidden = true
        }
    }
}
