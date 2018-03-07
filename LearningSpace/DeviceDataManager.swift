//
//  DeviceDataManager.swift
//  LearningSpace
//
//  Created by Pete Schwamb on 3/7/18.
//  Copyright © 2018 The Wildflower Foundation. All rights reserved.
//

import Foundation
import CoreMotion

class DeviceDataManager {
    
    static let motionUpdateInterval = TimeInterval(0.001)
    
    let knockDetectionQueue = OperationQueue()
    
    let motionManager: CMMotionManager = {
        let manager = CMMotionManager()
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = motionUpdateInterval // seconds
        }
        return manager
    }()
    
    func startKnockDetection() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: knockDetectionQueue) { (motion, error) in
                guard let motion = motion else {
                    return
                }
                
                let acc = motion.userAcceleration
                
                let magnitude = sqrt(acc.x*acc.x + acc.y*acc.y + acc.z*acc.z)

                if (magnitude > 0.7) {
                    print("mag = \(magnitude)")
                    NotificationCenter.default.post(name: .KnockDetected, object: self)
                }
            }
        }
    }
    
    func stopKnockDetection() {
        motionManager.stopDeviceMotionUpdates()
    }
}


extension Notification.Name {
    static let KnockDetected = Notification.Name(rawValue:  "org.wildflowerschools.LearningSpace.KnockDetected")
}
