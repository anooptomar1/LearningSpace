//
//  SCNVector3.swift
//  LearningSpace
//
//  Created by Pete Schwamb on 2/2/18.
//  Copyright © 2018 The Wildflower Foundation. All rights reserved.
//

import Foundation

import SceneKit

extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
    
    static func * (left: SCNVector3, right: SCNVector3) -> Float {
        return (left.x * right.x + left.y * right.y + left.z * right.z)
    }
    
    public func project(onto b: SCNVector3) -> SCNVector3 {
        let magb = b.length()
        if magb == 0 {
            fatalError("Zero vector provided to projection")
        }
        let adotb = self * b
        return (adotb / pow(magb, 2)) * b
    }
}

func /(left: SCNVector3, right: Float) -> SCNVector3 {
    let x = left.x / right
    let y = left.y / right
    let z = left.z / right
    
    return SCNVector3(x: x, y: y, z: z)
}

func *(left: SCNVector3, right: Float) -> SCNVector3 {
    let x = left.x * right
    let y = left.y * right
    let z = left.z * right
    
    return SCNVector3(x: x, y: y, z: z)
}


func /(left: SCNVector3, right: Int) -> SCNVector3 {
    return left / Float(right)
}

func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z)
}

func + (l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(l.x + r.x, l.y + r.y, l.z + r.z)
}

func *(left: Float, right: SCNVector3) -> SCNVector3 {
    return right * left
}


