//
//  ReferenceNode.swift
//  LearningSpace
//
//  Created by Pete Schwamb on 2/5/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

enum ReferenceType: Int {
    case wall1point1
    case wall1point2
    case wall2point1
    case wall3point1
    case wall4point1
}


class ReferenceNode: SCNNode {
    let anchor: ARImageAnchor
    let referenceType: ReferenceType
    let referenceImage: ARReferenceImage
    
    /// Whether the object is currently changing alignment
    private var isChangingAlignment: Bool = false


    init(anchor: ARImageAnchor, referenceType: ReferenceType, referenceImage: ARReferenceImage) {
        self.anchor = anchor
        self.referenceType = referenceType
        self.referenceImage = referenceImage
        super.init()

        let sphere = SCNSphere(radius: 0.025)
        sphere.firstMaterial?.diffuse.contents = UIColor(red: 30.0 / 255.0, green: 150.0 / 255.0, blue: 30.0 / 255.0, alpha: 1)
        let sphereNode = SCNNode(geometry: sphere)
        addChildNode(sphereNode)
    }
    
    func adjustOntoPlaneAnchor(_ anchor: ARPlaneAnchor, using node: SCNNode) {
        
        // Get the object's position in the plane's coordinate system.
        let planePosition = node.convertPosition(position, from: parent)
        
        // Check that the object is not already on the plane.
        guard planePosition.y != 0 else {
            print("ReferenceImage \(String(describing: referenceImage.name)) already on plane.")
            return
        }
        
        // Add 10% tolerance to the corners of the plane.
        let tolerance: Float = 0.1
        
        let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
        let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
        let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
        let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance
        
        guard (minX...maxX).contains(planePosition.x) && (minZ...maxZ).contains(planePosition.z) else {
            return
        }
        
        // Move onto the plane if it is near it (within 20 centimeters).
        let verticalAllowance: Float = 0.20
        let epsilon: Float = 0.001 // Do not update if the difference is less than 1 mm.
        let distanceToPlane = abs(planePosition.y)
        print("ReferenceImage \(String(describing: referenceImage.name)) distance to plane = \(distanceToPlane).")
        if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
//            SCNTransaction.begin()
//            SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // Move 2 mm per second.
//            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            position.y = anchor.transform.columns.3.y

            //updateAlignment(to: anchor.alignment, transform: simdWorldTransform, allowAnimation: false)
//            simdTransform = simdWorldTransform
//            simdTransform.translation = simdWorldPosition
//
//            SCNTransaction.commit()
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
