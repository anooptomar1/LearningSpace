//
//  Plane.swift
//  LearningSpace
//
//  Created by Pete Schwamb on 2/5/18.
//  Copyright © 2018 The Wildflower Foundation. All rights reserved.
//

import Foundation
import ARKit

class Plane: SCNNode {
    let anchor: ARPlaneAnchor
    let planeGeometry: SCNPlane

    init(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        self.planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))

        let material = SCNMaterial()
        let img = UIImage(named: "tron_grid")
        material.diffuse.contents = img
        self.planeGeometry.materials = [material]

        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)

        // Planes in SceneKit are vertical by default so we need to rotate 90degrees to match
        // planes in ARKit
        planeNode.eulerAngles.x = -.pi / 2

        //planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)

        super.init()

        setTextureScale()
        addChildNode(planeNode)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(anchor: ARPlaneAnchor) {
        // As the user moves around the extend and location of the plane
        // may be updated. We need to update our 3D geometry to match the
        // new parameters of the plane.
        self.planeGeometry.width = CGFloat(anchor.extent.x)
        self.planeGeometry.height = CGFloat(anchor.extent.z)

        // When the plane is first created it's center is 0,0,0 and the nodes
        // transform contains the translation parameters. As the plane is updated
        // the planes translation remains the same but it's center is updated so
        // we need to update the 3D geometry position
        self.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)

        setTextureScale()
    }

    func area() -> CGFloat {
        return self.planeGeometry.width * self.planeGeometry.height
    }

    func setTextureScale() {
        let width = Float(self.planeGeometry.width)
        let height = Float(self.planeGeometry.height)

        // As the width/height of the plane updates, we want our tron grid material to
        // cover the entire plane, repeating the texture over and over. Also if the
        // grid is less than 1 unit, we don't want to squash the texture to fit, so
        // scaling updates the texture co-ordinates to crop the texture in that case
        guard let material = planeGeometry.materials.first else {
            return
        }
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
    }
}
