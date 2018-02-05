//
//  SCNVector3.swift
//  ARKitImageRecognition
//
//  Created by Pete Schwamb on 2/2/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation

import SceneKit

extension SCNVector3 {
    func length() -> CGFloat {
        return CGFloat(sqrtf(x * x + y * y + z * z))
    }
}
func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z)
}
