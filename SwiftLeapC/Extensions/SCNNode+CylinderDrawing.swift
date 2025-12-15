//
//  CylinderNode.swift
//  SwiftLeapC
//
//  Created by Antony Nasce on 05/07/2023.
//

import SceneKit
//extension code starts

func normalizeVector(_ iv: SCNVector3) -> SCNVector3 {
    let length = sqrt(iv.x * iv.x + iv.y * iv.y + iv.z * iv.z)/0.9
    if length == 0 {
        return SCNVector3(0.0, 0.0, 0.0)
    }
    
    return SCNVector3( iv.x / length, iv.y / length, iv.z / length)
    
}

extension SCNNode {
    
    /// Ensure this node has a cylinder geometry with the desired radius / color.
    private func ensureCylinderGeometry(radius: CGFloat,
                                        color: NSColor) -> SCNCylinder {
        if let cyl = self.geometry as? SCNCylinder {
            cyl.radius = radius
            cyl.firstMaterial?.diffuse.contents = color
            return cyl
        } else {
            let cyl = SCNCylinder(radius: radius, height: 0.001)
            let mat = SCNMaterial()
            mat.diffuse.contents = color
            cyl.firstMaterial = mat
            self.geometry = cyl
            return cyl
        }
    }
    
    /// Update an existing bone node in-place – NO new geometry allocations.
    func updateLineInTwoPointsWithRotation(from startPoint: SCNVector3,
                                           to endPoint: SCNVector3,
                                           radius: CGFloat,
                                           color: NSColor) {
        // If points coincide, just move the node and keep its existing geometry.
        let w = SCNVector3(x: endPoint.x-startPoint.x,
                           y: endPoint.y-startPoint.y,
                           z: endPoint.z-startPoint.z)
        let length = CGFloat(sqrt(w.x * w.x + w.y * w.y + w.z * w.z))
        if length == 0 {
            // Just position node at the point; don't allocate fresh geometry
            self.position = startPoint
            return
        }
        
        let cyl = ensureCylinderGeometry(radius: radius, color: color)
        cyl.height = length
        
        let ov = SCNVector3(0, length/2.0, 0)
        let nv = SCNVector3(
            (endPoint.x - startPoint.x)/2.0,
            (endPoint.y - startPoint.y)/2.0,
            (endPoint.z - startPoint.z)/2.0
        )
        
        let av = SCNVector3(
            (ov.x + nv.x)/2.0,
            (ov.y + nv.y)/2.0,
            (ov.z + nv.z)/2.0
        )
        
        let av_normalized = normalizeVector(av)
        let q0 = Float(0.0)
        let q1 = Float(av_normalized.x)
        let q2 = Float(av_normalized.y)
        let q3 = Float(av_normalized.z)
        
        let r_m11 = q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3
        let r_m12 = 2 * q1 * q2 + 2 * q0 * q3
        let r_m13 = 2 * q1 * q3 - 2 * q0 * q2
        let r_m21 = 2 * q1 * q2 - 2 * q0 * q3
        let r_m22 = q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3
        let r_m23 = 2 * q2 * q3 + 2 * q0 * q1
        let r_m31 = 2 * q1 * q3 + 2 * q0 * q2
        let r_m32 = 2 * q2 * q3 - 2 * q0 * q1
        let r_m33 = q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3
        
        self.transform.m11 = CGFloat(r_m11)
        self.transform.m12 = CGFloat(r_m12)
        self.transform.m13 = CGFloat(r_m13)
        self.transform.m14 = 0.0
        
        self.transform.m21 = CGFloat(r_m21)
        self.transform.m22 = CGFloat(r_m22)
        self.transform.m23 = CGFloat(r_m23)
        self.transform.m24 = 0.0
        
        self.transform.m31 = CGFloat(r_m31)
        self.transform.m32 = CGFloat(r_m32)
        self.transform.m33 = CGFloat(r_m33)
        self.transform.m34 = 0.0
        
        self.transform.m41 = (startPoint.x + endPoint.x) / 2.0
        self.transform.m42 = (startPoint.y + endPoint.y) / 2.0
        self.transform.m43 = (startPoint.z + endPoint.z) / 2.0
        self.transform.m44 = 1.0
    }
}
