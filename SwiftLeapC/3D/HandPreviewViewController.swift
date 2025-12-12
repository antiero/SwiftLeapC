//
//  HandPreviewViewController.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 01/07/2023.
//

import Foundation
import SceneKit

class HandPreviewViewController: NSViewController, SCNSceneRendererDelegate {
    
    @IBOutlet weak var handPreview: SCNView!
    
    private let leftHandMaterial = SCNMaterial()
    private let rightHandMaterial = SCNMaterial()

    var leftHandColor: NSColor = .blue { didSet { leftHandMaterial.diffuse.contents = leftHandColor } }
    var rightHandColor: NSColor = .red { didSet { rightHandMaterial.diffuse.contents = rightHandColor } }
    
    var leftHand: SCNNode!
    var leftHandSphere: SCNNode!
    var leftPinkyMetacarpelSphere: SCNNode!
    
    var pinchDetector = LeapPinchDetector.sharedInstance
    var extendedFingerDetector = LeapExtendedFingerDetector.sharedInstance
    
    var rightHand: SCNNode!
    var rightHandSphere: SCNNode!
    var rightPinkyMetacarpelSphere: SCNNode!
    
    var handManager: LeapHandManager!
    
    var leftHandNodes = [SCNNode]()
    var rightHandNodes = [SCNNode]()
    
    var leftHandBoneNodes = [SCNNode]()
    var rightHandBoneNodes = [SCNNode]()
    
    var leftPinchNode: SCNNode!
    var rightPinchNode: SCNNode!
    
    let TOTAL_JOINT_COUNT = 4 * 5 // 4 joints per finger, 5 fingers
    let PINKY_BASE_INDEX = 3 * 4  // 4th finger (pinky), joint 0 index in joint list
    
    var showPinchIndicators = true
    var joinThumbProximal = true
    var joinMetacarpals = true
    var showPinkyMetacarpal = true
    var showExtendedFingerIndicators = true
    
    var leftSpherePositions = [SCNVector3]()
    var rightSpherePositions = [SCNVector3]()
    
    let SPHERE_RADIUS: CGFloat = 0.01
    
    private lazy var leftSphereGeo: SCNSphere = {
        let g = SCNSphere(radius: SPHERE_RADIUS)
        g.firstMaterial = leftHandMaterial
        return g
    }()

    private lazy var rightSphereGeo: SCNSphere = {
        let g = SCNSphere(radius: SPHERE_RADIUS)
        g.firstMaterial = rightHandMaterial
        return g
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("HandPreviewViewController.viewDidLoad")
        
        handManager = LeapHandManager.sharedInstance
        
        leftHandMaterial.diffuse.contents = leftHandColor
        rightHandMaterial.diffuse.contents = rightHandColor
        
        leftSpherePositions = Array(repeating: SCNVector3Zero, count: TOTAL_JOINT_COUNT)
        rightSpherePositions = Array(repeating: SCNVector3Zero, count: TOTAL_JOINT_COUNT)
        
        // Use the scene from Interface Builder if available (Hand3DScene.scn),
        // otherwise create a fresh one.
        let scene: SCNScene
        if let existing = handPreview.scene {
            scene = existing
        } else {
            print("No scene attached in IB, creating a new one.")
            scene = SCNScene()
            handPreview.scene = scene
        }
        
        // Configure SCNView + delegate so renderer(updateAtTime:) will fire
        handPreview.delegate = self
        handPreview.allowsCameraControl = true
        handPreview.showsStatistics = true
        handPreview.autoenablesDefaultLighting = true
        handPreview.isPlaying = true
        
        setupSceneGraph(on: scene)
    }
    
    deinit {
        handPreview?.delegate = nil
        handPreview?.scene = nil
    }
    
    // MARK: - Scene graph construction
    
    private func setupSceneGraph(on scene: SCNScene) {
        // Root nodes for left/right hands
        leftHand = SCNNode()
        leftHand.name = "LeftHand"
        scene.rootNode.addChildNode(leftHand)
        
        rightHand = SCNNode()
        rightHand.name = "RightHand"
        scene.rootNode.addChildNode(rightHand)
        
        // Palm spheres (use shared geometries/materials)
        leftHandSphere = SCNNode(geometry: leftSphereGeo)
        leftHandSphere.name = "LEFT"
        leftHand.addChildNode(leftHandSphere)

        rightHandSphere = SCNNode(geometry: rightSphereGeo)
        rightHandSphere.name = "RIGHT"
        rightHand.addChildNode(rightHandSphere)

        initialiseHandGeo(on: scene)
    }
    
    func getFingerJointIndex(fingerIndex: Int, jointIndex: Int) -> Int {
        return fingerIndex * 4 + jointIndex
    }
    
    func UpdatePinchIndicatorsForHand(hand: LEAP_HAND) {
        let pinchStrength = pinchDetector.pinchStrength(hand: hand)
        if hand.type == eLeapHandType_Left {
            leftPinchNode.isHidden = (pinchStrength < 0.9)
        } else if hand.type == eLeapHandType_Right {
            rightPinchNode.isHidden = (pinchStrength < 0.9)
        }
    }
    
    func initialiseHandGeo(on scene: SCNScene) {
        // LEFT JOINT SPHERES
        for nodeIx in 0..<20 {
            let newNode = SCNNode(geometry: leftSphereGeo)
            newNode.name = "LeftJoint-\(nodeIx)"
            leftHandNodes.append(newNode)
            leftHand.addChildNode(newNode)
        }
        
        // RIGHT JOINT SPHERES
        for nodeIx in 0..<20 {
            let newNode = SCNNode(geometry: rightSphereGeo)
            newNode.name = "RightJoint-\(nodeIx)"
            rightHandNodes.append(newNode)
            rightHand.addChildNode(newNode)
        }
        
        // LEFT BONE CYLINDERS
        for boneIx in 0...20 {
            let newBone = SCNNode()
            newBone.name = "LeftBone-\(boneIx)"
            newBone.updateLineInTwoPointsWithRotation(
                from: SCNVector3(1, 1, 1),
                to: SCNVector3(1, 1, 1),
                radius: SPHERE_RADIUS * 0.8,
                color: .white
            )
            leftHandBoneNodes.append(newBone)
            leftHand.addChildNode(newBone)
        }
        
        leftPinkyMetacarpelSphere = SCNNode(geometry: leftSphereGeo)
        leftHand.addChildNode(leftPinkyMetacarpelSphere)
        
        leftPinchNode = SCNNode(geometry: SCNSphere(radius: SPHERE_RADIUS * 1.5))
        leftPinchNode.geometry?.materials.first?.diffuse.contents = NSColor.systemYellow
        leftPinchNode.name = "LeftPinchIndicator"
        leftHand.addChildNode(leftPinchNode)
        leftPinchNode.isHidden = !showPinchIndicators
        
        // RIGHT BONE CYLINDERS
        for boneIx in 0...20 {
            let newBone = SCNNode()
            newBone.name = "RightBone-\(boneIx)"
            newBone.updateLineInTwoPointsWithRotation(
                from: SCNVector3(1, 1, 1),
                to: SCNVector3(1, 1, 1),
                radius: SPHERE_RADIUS * 0.8,
                color: .white
            )
            rightHandBoneNodes.append(newBone)
            rightHand.addChildNode(newBone)
        }
        
        rightPinkyMetacarpelSphere = SCNNode(geometry: rightSphereGeo)
        rightHand.addChildNode(rightPinkyMetacarpelSphere)
        
        rightPinchNode = SCNNode(geometry: SCNSphere(radius: SPHERE_RADIUS * 1.5))
        rightPinchNode.geometry?.materials.first?.diffuse.contents = NSColor.systemYellow
        rightPinchNode.name = "RightPinchIndicator"
        rightHand.addChildNode(rightPinchNode)
        rightPinchNode.isHidden = !showPinchIndicators
        
        // Camera (if your Hand3DScene.scn already has one, this just adds another)
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0.2, z: 0.7)
        cameraNode.look(at: SCNVector3(0, 0.2, 0))
        scene.rootNode.addChildNode(cameraNode)
    }
    
    // MARK: - Per-frame updates
    
    func UpdateSphereNodeWithPosition(node: SCNNode, position: SCNVector3) {
        node.position = position
    }
    
    func UpdateLeftHandBonePositions() {
        guard let leftLeapHand = handManager.leftHand else { return }
        
        leftHandSphere.position = handManager.leftPalmPosAsSCNVector3()
        
        let digits = leftLeapHand.digits
        UpdatePinchIndicatorsForHand(hand: leftLeapHand)
        
        let thumb  = digits.0
        let index  = digits.1
        let middle = digits.2
        let ring   = digits.3
        let pinky  = digits.4
        let fingers = [thumb, index, middle, ring, pinky]
        
        // Update joint spheres and cache positions
        for fingerIx in 0...4 {
            let finger = fingers[fingerIx]
            let bones = [finger.bones.0, finger.bones.1, finger.bones.2, finger.bones.3]
            for jointIx in 0...3 {
                let idx = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
                let position = bones[jointIx].next_joint
                let vec3 = SCNVector3(0.001 * position.x, 0.001 * position.y, 0.001 * position.z)
                leftSpherePositions[idx] = vec3
                UpdateSphereNodeWithPosition(node: leftHandNodes[idx], position: vec3)
            }
        }
        
        var leftBoneIndex = 0
        // Finger segments
        for fingerIx in 0...4 {
            for jointIx in 0...2 {
                let keyA = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
                let keyB = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx + 1)
                UpdateLeftCylinderBoneAtIndex(leftBoneIndex: leftBoneIndex, keyA: keyA, keyB: keyB)
                leftBoneIndex += 1
            }
        }
        
        if joinThumbProximal {
            let keyA = getFingerJointIndex(fingerIndex: 0, jointIndex: 0)
            let keyB = getFingerJointIndex(fingerIndex: 1, jointIndex: 0)
            UpdateLeftCylinderBoneAtIndex(leftBoneIndex: leftBoneIndex, keyA: keyA, keyB: keyB)
            leftBoneIndex += 1
        }
        
        if joinMetacarpals {
            for i in 1...3 {
                let keyA = getFingerJointIndex(fingerIndex: i, jointIndex: 0)
                let keyB = getFingerJointIndex(fingerIndex: i + 1, jointIndex: 0)
                UpdateLeftCylinderBoneAtIndex(leftBoneIndex: leftBoneIndex, keyA: keyA, keyB: keyB)
                leftBoneIndex += 1
            }
        }
        
        if showPinkyMetacarpal {
            let pinkyMetacarpal = pinky.metacarpal.prev_joint
            let indexMetacarpal = thumb.metacarpal.prev_joint
            let vecA = SCNVector3(0.001 * pinkyMetacarpal.x, 0.001 * pinkyMetacarpal.y, 0.001 * pinkyMetacarpal.z)
            let vecB = SCNVector3(0.001 * indexMetacarpal.x, 0.001 * indexMetacarpal.y, 0.001 * indexMetacarpal.z)
            
            SetNodePositionFromLeapVector(node: leftPinkyMetacarpelSphere, vec: pinkyMetacarpal)
            UpdateCylinderBoneAtIndex(nodeIn: leftHandBoneNodes[leftBoneIndex], vecA: vecA, vecB: vecB)
            leftBoneIndex += 1
            UpdateCylinderBoneAtIndex(nodeIn: leftHandBoneNodes[leftBoneIndex], vecA: vecA, vecB: leftSpherePositions[PINKY_BASE_INDEX])
        }
    }
    
    func UpdateLeftCylinderBoneAtIndex(leftBoneIndex: Int, keyA: Int, keyB: Int) {
        leftHandBoneNodes[leftBoneIndex].updateLineInTwoPointsWithRotation(
            from: leftSpherePositions[keyA],
            to: leftSpherePositions[keyB],
            radius: SPHERE_RADIUS,
            color: .white
        )
    }
    
    func UpdateRightCylinderBoneAtIndex(rightBoneIndex: Int, keyA: Int, keyB: Int) {
        rightHandBoneNodes[rightBoneIndex].updateLineInTwoPointsWithRotation(
            from: rightSpherePositions[keyA],
            to: rightSpherePositions[keyB],
            radius: SPHERE_RADIUS,
            color: .white
        )
    }
    
    func UpdateCylinderBoneAtIndex(nodeIn: SCNNode, vecA: SCNVector3, vecB: SCNVector3) {
        nodeIn.updateLineInTwoPointsWithRotation(
            from: vecA,
            to: vecB,
            radius: SPHERE_RADIUS,
            color: .white
        )
    }
    
    func SetNodePositionFromLeapVector(node: SCNNode, vec: LEAP_VECTOR) {
        let newPos = SCNVector3(0.001 * vec.x, 0.001 * vec.y, 0.001 * vec.z)
        node.position = newPos
    }
    
    func UpdateRightHandBonePositions() {
        guard let rightLeapHand = handManager.rightHand else { return }
        
        rightHandSphere.position = handManager.rightPalmPosAsSCNVector3()
        
        let digits = rightLeapHand.digits
        UpdatePinchIndicatorsForHand(hand: rightLeapHand)
        
        let thumb  = digits.0
        let index  = digits.1
        let middle = digits.2
        let ring   = digits.3
        let pinky  = digits.4
        let fingers = [thumb, index, middle, ring, pinky]
        
        for fingerIx in 0...4 {
            let finger = fingers[fingerIx]
            let bones = [finger.bones.0, finger.bones.1, finger.bones.2, finger.bones.3]
            for jointIx in 0...3 {
                let idx = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
                let position = bones[jointIx].next_joint
                let vec3 = SCNVector3(0.001 * position.x, 0.001 * position.y, 0.001 * position.z)
                rightSpherePositions[idx] = vec3
                UpdateSphereNodeWithPosition(node: rightHandNodes[idx], position: vec3)
            }
        }
        
        var rightBoneIndex = 0
        // Finger segments
        for fingerIx in 0...4 {
            for jointIx in 0...2 {
                let keyA = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx)
                let keyB = getFingerJointIndex(fingerIndex: fingerIx, jointIndex: jointIx + 1)
                UpdateRightCylinderBoneAtIndex(rightBoneIndex: rightBoneIndex, keyA: keyA, keyB: keyB)
                rightBoneIndex += 1
            }
        }
        
        if joinThumbProximal {
            let keyA = getFingerJointIndex(fingerIndex: 0, jointIndex: 0)
            let keyB = getFingerJointIndex(fingerIndex: 1, jointIndex: 0)
            UpdateRightCylinderBoneAtIndex(rightBoneIndex: rightBoneIndex, keyA: keyA, keyB: keyB)
            rightBoneIndex += 1
        }
        
        if joinMetacarpals {
            for i in 1...3 {
                let keyA = getFingerJointIndex(fingerIndex: i, jointIndex: 0)
                let keyB = getFingerJointIndex(fingerIndex: i + 1, jointIndex: 0)
                UpdateRightCylinderBoneAtIndex(rightBoneIndex: rightBoneIndex, keyA: keyA, keyB: keyB)
                rightBoneIndex += 1
            }
        }
        
        if showPinkyMetacarpal {
            let pinkyMetacarpal = pinky.metacarpal.prev_joint
            let indexMetacarpal = thumb.metacarpal.prev_joint
            let vecA = SCNVector3(0.001 * pinkyMetacarpal.x, 0.001 * pinkyMetacarpal.y, 0.001 * pinkyMetacarpal.z)
            let vecB = SCNVector3(0.001 * indexMetacarpal.x, 0.001 * indexMetacarpal.y, 0.001 * indexMetacarpal.z)
            
            SetNodePositionFromLeapVector(node: rightPinkyMetacarpelSphere, vec: pinkyMetacarpal)
            UpdateCylinderBoneAtIndex(nodeIn: rightHandBoneNodes[rightBoneIndex], vecA: vecA, vecB: vecB)
            rightBoneIndex += 1
            UpdateCylinderBoneAtIndex(nodeIn: rightHandBoneNodes[rightBoneIndex], vecA: vecA, vecB: rightSpherePositions[PINKY_BASE_INDEX])
        }
    }
    
    // MARK: - SCNSceneRendererDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if handManager.rightHandPresent() {
            rightHand.isHidden = false
            UpdateRightHandBonePositions()
        } else {
            rightHand.isHidden = true
        }
        
        if handManager.leftHandPresent() {
            leftHand.isHidden = false
            UpdateLeftHandBonePositions()
        } else {
            leftHand.isHidden = true
        }
    }
}
