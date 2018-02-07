//
//  Utilities.swift
//  LearningSpace
//
//  Created by Pete Schwamb on 2/6/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import ARKit

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
     */
    var translation: float3 {
        get {
            let translation = columns.3
            return float3(translation.x, translation.y, translation.z)
        }
        set(newValue) {
            columns.3 = float4(newValue.x, newValue.y, newValue.z, columns.3.w)
        }
    }
}
