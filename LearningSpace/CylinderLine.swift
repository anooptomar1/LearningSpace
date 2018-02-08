//
//  CylinderLine.swift
//  LearningSpace
//
//  Created by Pete Schwamb on 2/7/18.
//  Copyright © 2018 The Wildflower Foundation. All rights reserved.
//

import Foundation
import SceneKit

class CylinderLine: SCNNode
{
    init(v1: SCNVector3,//source
        v2: SCNVector3,//destination
        radius: CGFloat,//somes option for the cylinder
        radSegmentCount: Int, //other option
        color: UIColor )// color of your node object
    {
        super.init()
        
        //Calcul the height of our line
        let height = Float((v1 - v2).length())
        
        //set position to v1 coordonate
        position = v1
        
        //Create the second node to draw direction vector
        let nodeV2 = SCNNode()
        
        //define his position
        nodeV2.position = v2
        
        //Align Z axis
        let zAlign = SCNNode()
        zAlign.eulerAngles.x = Float.pi / 2
        
        //create our cylinder
        let cyl = SCNCylinder(radius: radius, height: CGFloat(height))
        cyl.radialSegmentCount = radSegmentCount
        cyl.firstMaterial?.diffuse.contents = color
        
        //Create node with cylinder
        let nodeCyl = SCNNode(geometry: cyl )
        nodeCyl.position.y = -height/2
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
