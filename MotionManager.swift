//
//  MotionManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/7/6.
//

import UIKit
import CoreMotion

class MotionManager: NSObject {
    static let `default`: MotionManager = {
        return MotionManager()
    }()
    
    ///  开始更新频率
    public func startMotionUpdate(handler: @escaping (()->())){
        if !self.motionManager.isDeviceMotionActive && self.motionManager.isDeviceMotionAvailable {
            self.motionManager.startDeviceMotionUpdates(to: OperationQueue()) { [weak self] motion, error in
                guard let motion = motion else { return }
                //该属性返回地球重力对该设备在X、Y、Z轴上施加的重力加速度（只是地球重力，手动晃的再厉害也不管用）
                // let gravity = motion.gravity
                let userAcceleration = motion.userAcceleration
                log.info("userAcceleration:\(userAcceleration)")
                
                //值越大说明摇动的幅度越大
                let num = 0.3
                if (fabs(userAcceleration.x) > num) || (fabs(userAcceleration.y) > num) || (fabs(userAcceleration.z) > num) {
                    //停止更新
                    self?.stopMotion()
                    DispatchQueue.main.async {
                        handler()
                    }
                }
            }
        }
    }
    
   /// 停止更新频率
    public func stopMotion(){
        self.motionManager.stopDeviceMotionUpdates()
    }
    
    private lazy var motionManager: CMMotionManager = {
        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 0.2
        return manager
    }()
}
