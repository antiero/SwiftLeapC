//
//  RKHandRig.swift
//  SwiftLeapC
//
//  RealityKit rig for rendering a Leap hand as joints + bones.
//

import AppKit
import RealityKit
import simd

final class RKHandRig {

    let root = Entity()

    let palm: ModelEntity
    let pinch: ModelEntity
    let pinkyHelper: ModelEntity

    let joints: [ModelEntity]
    private let bones: [ModelEntity]

    private let boneRadius: Float

    init(handColor: NSColor, sphereRadius: Float) {
        self.boneRadius = sphereRadius * 0.8

        // Materials (SimpleMaterial initializer works well on macOS)
        let handMat = SimpleMaterial(color: handColor, roughness: 1.0, isMetallic: false)
        let boneMat = SimpleMaterial(color: .white, roughness: 1.0, isMetallic: false)
        let pinchMat = SimpleMaterial(color: .systemYellow, roughness: 1.0, isMetallic: false)

        // Meshes
        let sphereMesh = MeshResource.generateSphere(radius: sphereRadius)
        let pinchMesh = MeshResource.generateSphere(radius: sphereRadius * 1.5)
        let boneMesh = MeshResource.generateCylinder(height: 1.0, radius: boneRadius)

        // Entities
        palm = ModelEntity(mesh: sphereMesh, materials: [handMat])
        root.addChild(palm)

        pinch = ModelEntity(mesh: pinchMesh, materials: [pinchMat])
        pinch.isEnabled = false
        root.addChild(pinch)

        pinkyHelper = ModelEntity(mesh: sphereMesh, materials: [handMat])
        pinkyHelper.isEnabled = false
        root.addChild(pinkyHelper)

        var js: [ModelEntity] = []
        js.reserveCapacity(21)
        for _ in 0..<21 {
            let j = ModelEntity(mesh: sphereMesh, materials: [handMat])
            j.isEnabled = false
            root.addChild(j)
            js.append(j)
        }
        joints = js

        var bs: [ModelEntity] = []
        bs.reserveCapacity(32)
        for _ in 0..<32 {
            let b = ModelEntity(mesh: boneMesh, materials: [boneMat])
            b.isEnabled = false
            root.addChild(b)
            bs.append(b)
        }
        bones = bs
    }

    func setHidden(_ hidden: Bool) {
        root.isEnabled = !hidden
    }

    func updateBone(at index: Int, from: SIMD3<Float>, to: SIMD3<Float>) {
        guard index >= 0 && index < bones.count else { return }

        let b = bones[index]
        let d = to - from
        let len = simd_length(d)

        guard len > 0.0001 else {
            b.isEnabled = false
            return
        }

        let mid = (from + to) * 0.5
        let dir = d / len

        // Cylinder is height=1 along +Y; rotate + scale Y to match segment length.
        let up = SIMD3<Float>(0, 1, 0)
        let rot = simd_quatf(from: up, to: dir)

        b.transform = Transform(
            scale: SIMD3<Float>(1, len, 1),
            rotation: rot,
            translation: mid
        )
        b.isEnabled = true
    }

    func hideBone(at index: Int) {
        guard index >= 0 && index < bones.count else { return }
        bones[index].isEnabled = false
    }

    func hideBones(from startIndex: Int) {
        guard startIndex < bones.count else { return }
        for i in startIndex..<bones.count {
            bones[i].isEnabled = false
        }
    }
}
