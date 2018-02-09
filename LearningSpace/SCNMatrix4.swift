//
//  SCNMatrix4.swift
//  LearningSpace
//
//  Created by Pete Schwamb on 2/9/18.
//  Copyright © 2018 The Wildflower Foundation. All rights reserved.
//

import Foundation

import SceneKit

func *(left: SCNMatrix4, right: SCNMatrix4) -> SCNMatrix4 {
    return (SCNMatrix4Mult(left, right))
}


