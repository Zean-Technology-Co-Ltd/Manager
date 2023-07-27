//
//  BuriedManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/5/29.
//  https://manual.sensorsdata.cn/sa/latest/tech_sdk_client_ios_use-7538614.html

import UIKit
import SensorsAnalyticsSDK

class TrackManager: NSObject {
    static func register(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?){
        let options = SAConfigOptions.init(serverURL: NNApiConst.APIKey.trackURL, launchOptions: launchOptions)
        //开启全埋点
        options.autoTrackEventType = [
            .eventTypeAppStart,
            .eventTypeAppEnd,
//            .eventTypeAppClick,
            .eventTypeAppViewScreen]
#if DEBUG
        //开启log
        options.enableLog = false
#endif
        /**
         * 其他配置，如开启可视化全埋点
         */
        // 注册自定义属性插件
        options.register(PropertyPlugin())
        //初始化SDK
        SensorsAnalyticsSDK.start(configOptions: options)
        SensorsAnalyticsSDK.sharedInstance()?.registerDynamicSuperProperties({
            return [
                "charging": UIDevice.getBatteryState(),
                "battery": UIDevice.getBatteryLevel(),
            ]
        })
    }
    
    static let `default`: TrackManager = {
        return TrackManager()
    }()
    
    public func setBaseMsg(){
        SensorsAnalyticsSDK.sharedInstance()?.login(Authorization.default.token?.memberId ?? "")
        let data = SensorsAnalyticsSDK.sharedInstance()?.getPresetProperties()
        SensorsAnalyticsSDK.sharedInstance()?.set([
            "loginId": Authorization.default.token?.memberId ?? "",
            "name": Authorization.default.oauthUser?.realName ?? "",
            "cardNo": Authorization.default.oauthUser?.cardNo ?? "",
            "mobile": Authorization.default.token?.username ?? "",
            "tenant": NNApiConst.ServiceKey.Tenant,
            "deviceId": data?["$device_id"] ?? "",
            "deviceType": "iOS Phone"
        ])
    }
    
    public func track(_ type: TrackType, property: [String: Any]? = nil){
        SensorsAnalyticsSDK
            .sharedInstance()?
            .track(type.rawValue, withProperties: property)
    }
    
    public func deleteAll(){
        SensorsAnalyticsSDK.sharedInstance()?.deleteAll()
    }
}
