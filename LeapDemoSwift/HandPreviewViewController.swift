//
//  HandPreviewViewController.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 01/07/2023.
//  Copyright © 2023 Kelly Innes. All rights reserved.
//

import Foundation
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
    
    var spherePositions : [SCNVector3] = [SCNVector3]()
    var leftHandNodes : [SCNNode] = [SCNNode]()
    
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
        let sphereGeometry = SCNSphere(radius: 0.01)
        leftHandSphere = SCNNode(geometry: sphereGeometry)
        leftHandSphere.position = SCNVector3(x: -0.1, y: 0, z: 0)
        leftHandSphere.name = "LEFT"
        scene?.rootNode.addChildNode(leftHandSphere)
        
        rightHandSphere = SCNNode(geometry: sphereGeometry)
        rightHandSphere.position = SCNVector3(x: 0.1, y: 0, z: 0)
        rightHandSphere.name = "LEFT"
        scene?.rootNode.addChildNode(rightHandSphere)
    }
    
    func getFingerJointIndex(fingerIndex: Int, jointIndex: Int) -> Int
    {
        return fingerIndex * 4 + jointIndex;
    }
    
    func UpdateLeftHandBonePositions(){
        if (handManager.leftHand == nil){
            return
        }
        
        if (leftHandNodes.count != TOTAL_JOINT_COUNT)
        {
            spherePositions = [SCNVector3](repeating: SCNVector3(), count: TOTAL_JOINT_COUNT)
            InitialiseLeftHandSpheres()
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
                UpdateSphereNodeWithPosition(node: leftHandNodes[jointIx], position: vec3)
                //print("LEFT NODE COUNT: ", leftHandNodes.count)
            }
        }
    }
    
    func UpdateSphereNodeWithPosition(node : SCNNode, position : SCNVector3){
        if (node != nil){
            //print("Updating Position: ", position)
            node.position = position
        }
    }
    
    func InitialiseLeftHandSpheres()
    {
        print("InitialiseLeftHandSpheres")
        let sphereGeometry = SCNSphere(radius: CGFloat(SPHERE_RADIUS))
        for nodeIx in 0...19{
            print("ADDING CHILD NODE for index: ", nodeIx)
            let sphere = SCNNode(geometry: sphereGeometry)
            leftHandNodes.append(sphere)
            scene?.rootNode.addChildNode(leftHandNodes[nodeIx])
        }
    }
    
    func updateHandPositions() {
        rightLoop: if (handManager.rightHandPresent()){
            if (handManager.rightHand == nil){
                break rightLoop
            }
            if let newRightHandPosition = handManager.rightHandPosition {
                rightHandSphere.position = handManager.rightPalmPosAsSCNVector3()
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
