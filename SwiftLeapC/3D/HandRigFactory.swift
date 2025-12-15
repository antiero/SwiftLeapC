//
//  HandRigFactory.swift
//  SwiftLeapC
//
//  Created by ChatGPT (refactor) on 12/12/2025.
//

import SceneKit

enum HandRigFactory {
    
    static func buildRigs(
        in scene: SCNScene,
        leftSphereGeo: SCNGeometry,
        rightSphereGeo: SCNGeometry,
        sphereRadius: CGFloat,
        showPinchIndicators: Bool
    ) -> (left: HandRig, right: HandRig) {
        
        let left = HandRig(
            side: .left,
            sphereGeometry: leftSphereGeo,
            sphereRadius: sphereRadius,
            showPinchIndicators: showPinchIndicators
        )
        scene.rootNode.addChildNode(left.root)
        
        let right = HandRig(
            side: .right,
            sphereGeometry: rightSphereGeo,
            sphereRadius: sphereRadius,
            showPinchIndicators: showPinchIndicators
        )
        scene.rootNode.addChildNode(right.root)
        
        return (left, right)
    }
    
    /// Preserves your previous behavior: always adds an extra camera node.
    static func addDefaultCamera(to scene: SCNScene) {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0.2, z: 0.7)
        cameraNode.look(at: SCNVector3(0, 0.2, 0))
        scene.rootNode.addChildNode(cameraNode)
    }
}
