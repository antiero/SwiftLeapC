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

class CylinderLine: SCNNode
{
    init( parent: SCNNode,//Needed to add destination point of your line
        v1: SCNVector3,//source
        v2: SCNVector3,//destination
        radius: CGFloat,//somes option for the cylinder
        radSegmentCount: Int, //other option
        color: NSColor )// color of your node object
    {
        super.init()

        //Calcul the height of our line
        let  height = v1.distance(receiver: v2)

        //set position to v1 coordonate
        position = v1

        //Create the second node to draw direction vector
        let nodeV2 = SCNNode()

        //define his position
        nodeV2.position = v2
        //add it to parent
        parent.addChildNode(nodeV2)

        //Align Z axis
        let zAlign = SCNNode()
        zAlign.eulerAngles.x = CGFloat(Double.pi / 2.0)

        //create our cylinder
        let cyl = SCNCylinder(radius: radius, height: CGFloat(height))
        cyl.radialSegmentCount = radSegmentCount
        cyl.firstMaterial?.diffuse.contents = color

        //Create node with cylinder
        let nodeCyl = SCNNode(geometry: cyl )
        nodeCyl.position.y = CGFloat(-height/2)
        zAlign.addChildNode(nodeCyl)

        //Add it to child
        addChildNode(zAlign)

        //set contrainte direction to our vector
        constraints = [SCNLookAtConstraint(target: nodeV2)]
    }

    override init() {
        super.init()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

private extension SCNVector3{
    func distance(receiver:SCNVector3) -> Float{
        let xd = receiver.x - self.x
        let yd = receiver.y - self.y
        let zd = receiver.z - self.z
        let distance = Float(sqrt(xd * xd + yd * yd + zd * zd))

        if (distance < 0){
            return (distance * -1)
        } else {
            return (distance)
        }
    }
}


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
    
    var rightSpherePositions : [SCNVector3] = [SCNVector3]()
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
                let position = bones[jointIx].next_joint
                let vec3 = SCNVector3(0.001*position.x, 0.001*position.y, 0.001*position.z)
                leftSpherePositions[index] = vec3
                UpdateSphereNodeWithPosition(node: leftHandNodes[index], position: vec3)
            }
        }
        
        //Draw cylinders between finger joints
//        for fingerIx in 0...4 {
//            for jointIx in 0...2
//            {
//                let keyA = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
//                let keyB = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx + 1)
//                if (keyA < leftCylinderNodes.count){
//                    leftCylinderNodes[keyA] = CylinderLine(parent: leftHandSphere, v1: leftSpherePositions[keyA], v2: leftSpherePositions[keyB], radius: 0.01, radSegmentCount: 5, color: NSColor.white)
//                    scene?.rootNode.addChildNode(leftCylinderNodes[keyA]])
//                }
//            }
//        }
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
        
//        for boneIx in 0...14 {
//            //let bone = DrawCylinder(positionA: leftHandNodes[boneIx].position, positionB: leftHandNodes[boneIx+1].position, inScene: scene)
//            let bone = CylinderLine(parent: leftHandSphere, v1: leftHandNodes[boneIx].position, v2: leftHandNodes[boneIx+1].position, radius: 0.01, radSegmentCount: 5, color: NSColor.white)
//            leftCylinderNodes.append(bone)
//            scene?.rootNode.addChildNode(leftCylinderNodes[boneIx])
//        }
        
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
