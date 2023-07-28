//
//  AuthorizedManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/7/24.
//

import UIKit
import Photos
import UserNotifications
import Contacts
import Alamofire

enum AppAuthorizationStatus : Int, @unchecked Sendable {
    ///已拒绝
    case denied
    ///未授权
    case notDetermined
    ///已授权
    case authorized
    ///该应用程序无权访问
    case restricted
    ///其他
    case none
}

enum AppAuthorizationType: String {
    ///相机
    case camera = "相机"
    ///麦克风
    case microphone = "麦克风"
    ///相册
    case photoLibrary = "相册"
    ///定位
    case location = "定位"
    ///推送
    case notification = "推送"
    ///通讯录
    case contactBook = "通讯录"
    ///网络
    case cellularData = "网络"
}

class AppAuthorizedManager: NSObject {
    ///相机权限
    class func cameraAuthorized() -> AppAuthorizationStatus{
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied : //未授权
            return .denied
        case .notDetermined : //不确定
            return .notDetermined
        case .authorized:
            return .authorized
        case .restricted:
            return .restricted
        @unknown default:
            return .none
        }
    }
    ///麦克风权限
    class func microphoneAuthorized() -> AppAuthorizationStatus{
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .denied : //未授权
            return .denied
        case .notDetermined : //不确定
            return .notDetermined
        case .authorized:
            return .authorized
        case .restricted:
            return .restricted
        @unknown default:
            return .none
        }
    }
    ///相册权限
    class func photoLibraryAuthorized() -> AppAuthorizationStatus{
        switch PHPhotoLibrary.authorizationStatus() {
        case .denied :
            return .denied
        case .notDetermined :
            return .notDetermined
        case .authorized, .limited:
            return .authorized
        case .restricted :
            return .restricted
        @unknown default:
            return .none
        }
    }
    ///定位权限
    class func locationAuthorized() -> AppAuthorizationStatus{
        switch CLLocationManager.authorizationStatus() {
        case .denied :
            return .denied
        case .notDetermined :
            return .notDetermined
        case .authorizedAlways, .authorizedWhenInUse :
            return .authorized
        case .restricted :
            return .restricted
        @unknown default:
            return .none
        }
    }
    ///通知权限
    class func notificationAuthorized(callback: @escaping((AppAuthorizationStatus) -> Void)){
        UNUserNotificationCenter.current().getNotificationSettings { setting in
            switch setting.authorizationStatus {
            case .denied :
                callback(.denied)
            case .notDetermined :
                callback(.notDetermined)
            case .authorized :
                callback(.authorized)
            case .provisional, .ephemeral:
                callback(.restricted)
            @unknown default:
                callback(.none)
            }
        }
    }
    ///通讯录权限
    class func contactBookAuthorized() -> AppAuthorizationStatus{
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .denied :
            return .denied
        case .notDetermined :
            return .notDetermined
        case .authorized :
            return .authorized
        case .restricted :
            return .restricted
        @unknown default:
            return .none
        }
    }
    
    
    /// 打开设置页面
    class func openSeetingPage(_ type: AppAuthorizationType, showVC: UIViewController){
        AlertController.nn_CustomViewWith(showVC,
                                          title: "\(type.rawValue)权限已关闭",
                                          content: "是否前往设置重新打开",
                                          leftBtnTitle: "取消",
                                          rightBtnTitle: "去打开") { isSeeting in
            if isSeeting == true,
                let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    class func resetSeetingPage(showVC: UIViewController){
        AlertController.nn_CustomViewWith(showVC,
                                          content: "是否前往设置修改授权",
                                          leftBtnTitle: "取消",
                                          rightBtnTitle: "去设置") { isSeeting in
            if isSeeting == true,
                let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    /// 关闭设置页面
    class func closeSeetingPage(){
        AlertController.dismiss()
    }
}
