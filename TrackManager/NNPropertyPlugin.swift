//
//  NNPropertyPlugin.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/5/29.
// SmoothScroll

import UIKit
import SensorsAnalyticsSDK

class NNPropertyPlugin: SAPropertyPlugin {
    
    override func isMatched(with filter: SAPropertyPluginEventFilter) -> Bool {
        return filter.type.contains(SAEventType.default)
    }

    override func priority() -> SAPropertyPluginPriority {
        return SAPropertyPluginPriority.default
    }

    override func properties() -> [String : Any] {
        let data = SensorsAnalyticsSDK.sharedInstance()?.getPresetProperties()
        return ["tenant": NNApiConst.ServiceKey.Tenant,
                "deviceId": data?["device_id"] ?? "",
                "deviceType": "iOS Phone"]
    }
}
