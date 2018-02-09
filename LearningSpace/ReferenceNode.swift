//
//  ReferenceNode.swift
//  LearningSpace
//
//  Created by Pete Schwamb on 2/5/18.
//  Copyright © 2018 The Wildflower Foundation. All rights reserved.
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
                
        let newPosition = SCNVector3Make(planePosition.x, 0, planePosition.z)
        position = node.convertPosition(newPosition, to: parent)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
