//
//  FaceManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/6/26.
//

import UIKit
import AVFoundation

class FaceManager: NSObject {
    private var faceVC: STLivenessController?
    private var callback: ((Data, UIImage)->())?
    private var faceDataCallback: ((Data)->())?
    private let lock = NSLock()
    private var writeManager: AVAssetWriteManager?
    private var videoUrl: URL?
    
    deinit {
        log.info(#function)
    }
    static let `default`: FaceManager = {
        return FaceManager()
    }()
    
    func face(superVC: UIViewController, callback:@escaping ((Data, UIImage)->()), faceDataCallback: ((Data)->())? = nil){
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .restricted || authStatus == .denied {
            Toast.showError("相机权限获取失败:请在设置-隐私-相机中开启后重试")
            return;
        }
        self.faceDataCallback = faceDataCallback
        self.callback = callback
        // 借用MAP无序链表特性
        let map = [
            "BLINK": STIDLivenessFaceDetectionType.BLINK.rawValue,
            "MOUTH": STIDLivenessFaceDetectionType.MOUTH.rawValue,
            "NOD": STIDLivenessFaceDetectionType.NOD.rawValue,
            "YAW": STIDLivenessFaceDetectionType.YAW.rawValue]
        let sequenceArray = map.values.map { value in
            return value as Int
        }
        let livenessVC = STLivenessController(setDelegate: self, detectionSequence: sequenceArray)!
        //设置每个模块的超时时间
        livenessVC.detector.setTimeOutDuration(faceData.detectTimeout)
        // 设置活体检测复杂度
        livenessVC.detector.setComplexity(STIDLivenessFaceComplexity.COMPLEXITY_NORMAL)
        // 设置人脸远近判断条件
        livenessVC.detector.setFaceDistanceRateWithFarRate(CGFloat(faceData.faceDistanceFarRate),
                                                           closeRate: CGFloat(faceData.faceDistanceCloseRate))
        // 设置是否进行眉毛遮挡的检测，如不设置默认为不检测
        livenessVC.detector.setBrowOcclusionEnable(faceData.isBrowOcclusionEnable)
        // 光照检测，默认关闭
        livenessVC.detector.setIlluminationFilterEnable(faceData.isIlluminationFilterEnable,
                                                        darkLightThreshold: faceData.lowLightThreshold,
                                                        strongLightThreshold: faceData.brightThreshold)
        
        // 模糊检测，默认关闭
        livenessVC.detector.setBlurryFilterEnable(faceData.isBlurryFilterEnable,
                                                  threshold: faceData.blurryThreshold)
        livenessVC.isVoicePrompt = true
        
        // 活体人脸照片中眼睛睁眼检测，默认关闭
        let faceSelectFilter = STLivenessFaceSelectFilter()
        faceSelectFilter.checkEyeStatus = faceData.isEyeOpenFilterEnable
        faceSelectFilter.eyeThreshold = faceData.eyeOpenThreshold;
        livenessVC.detector.faceSelectFilter = faceSelectFilter
        
        // 设置签名图的处理规则
        let rule = STLivenessImageProcessRule()
        rule.imageCropRule.offsetX = 0
        rule.imageCropRule.offsetY = -40
        rule.imageCropRule.scaleX = 1.2
        rule.imageCropRule.scaleY = 2
        rule.topSize = 50
        livenessVC.detector.setImageProcessRule(rule)
        
        /// 设置默认语音提示状态,如不设置默认为开启
        livenessVC.isVoicePrompt = true
        /// 是否需要在检测失败后重新开始检测，默认为NO
        livenessVC.isNeedReStart = faceData.isNeedReStart
        superVC.navigationController?.pushViewController(livenessVC, animated: true)
        livenessVC.navigationController?.navigationBar.isTranslucent = true
        self.faceVC = livenessVC
        
        self.writeManager = AVAssetWriteManager()
        self.videoUrl = URL(fileURLWithPath: self.filePath())
        self.writeManager?.startWrite(videoUrl)
        
        MotionManager.default.startMotionUpdate {
            TrackManager.default.track(.Gyroscope, property: ["motionState": "1"])
        }
    }
    // MARK: Private Method
    private func endAssetWrite(){
        self.writeManager?.stopWrite()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.writeManager?.getVideoData { [weak self] data in
                if let data = data {
                    self?.faceDataCallback?(data)
                }
            }
            self?.writeManager?.destroyWrite()
        }
    }
    
    private func popViewController(){
        MotionManager.default.stopMotion()
        self.faceVC?.navigationController?.navigationBar.isTranslucent = false
        self.faceVC?.navigationController?.popViewController(animated: true)
    }
    
    public func deleteRecordingFile(){
        if let videoUrl = self.videoUrl,
            FileManager.default.fileExists(atPath: videoUrl.absoluteString){
            do {
                try FileManager.default.removeItem(atPath: videoUrl.absoluteString)
            } catch {
                log.info("视频文件移除失败")
            }
        }
    }
    
    private func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        return paths + "/\(Date.todayTimestamp)" + ".mp4"
    }
    // MARK: Private set
    private lazy var faceData: LivingSettingGLobalData = {
        return LivingSettingGLobalData.sharedInstance()
    }()
}

extension FaceManager: STLivenessDetectorDelegate{
    func st_captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        self.lock.lock()
        //视频
        if connection == captureOutput.connection(with: .video) {
            if (self.writeManager?.outputVideoFormatDescription == nil) == false {
                let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
                self.writeManager?.outputVideoFormatDescription = formatDescription
            } else {
                self.writeManager?.append(sampleBuffer, ofMediaType: AVMediaType.video.rawValue)
            }
        }
        if connection == captureOutput.connection(with: .audio) {
            if (self.writeManager?.outputVideoFormatDescription == nil) == false {
                let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
                self.writeManager?.outputAudioFormatDescription = formatDescription
            } else {
                self.writeManager?.append(sampleBuffer, ofMediaType: AVMediaType.audio.rawValue)
            }
        }
        self.lock.unlock()
    }
    
    func livenessSuccess(with resultInfo: STLivenessResultInfo!, cloudInfo: STLivenessCloudInfo!) {
        guard let livenessImage = resultInfo.croppedImages.last else { return }
        self.callback?(resultInfo.protobufData, livenessImage.image)
        self.endAssetWrite()
        popViewController()
    }
    
    func livenessFailure(with resultInfo: STLivenessResultInfo!, cloudInfo: STLivenessCloudInfo!) {
        var cloudStr = ""
        let livenessStr = messageStringByLivenessResult(result: resultInfo.livenessResult,
                                                                   faceError: resultInfo.faceError)
        if (resultInfo.livenessResult == STIDLivenessResult.E_API_KEY_INVALID ||
            resultInfo.livenessResult == STIDLivenessResult.E_SERVER_ACCESS) {
            cloudStr = messageStringBycloudInternalCode(result: STIDLivenessCloudInternalCode(rawValue: cloudInfo.cloudInternalCode) ?? STIDLivenessCloudInternalCode.CLOUD_INTERNAL_DEFAULT)
        }
        if !String.isEmpty(livenessStr) && !String.isEmpty(cloudStr) {
            Toast.showError("\(livenessStr)\n\(cloudStr)")
        } else if !String.isEmpty(livenessStr) {
            Toast.showError(livenessStr)
        } else if !String.isEmpty(cloudStr) {
            Toast.showError(cloudStr)
        }
        self.endAssetWrite()
        popViewController()
    }
    
    func livenessDidCancel() {
        log.info("活体检测已取消")
        self.writeManager?.destroyWrite()
        popViewController()
        self.faceVC = nil
    }
    
    private func messageStringByLivenessResult(result: STIDLivenessResult, faceError: STIDLivenessFaceError) -> String{
        switch result {
        case STIDLivenessResult.OK:
            return ""
        case STIDLivenessResult.E_LICENSE_INVALID:
            return "未通过授权验证"
        case STIDLivenessResult.E_LICENSE_FILE_NOT_FOUND:
            return "授权文件不存在"
        case STIDLivenessResult.E_LICENSE_BUNDLE_ID_INVALID:
            return "绑定包名错误"
        case STIDLivenessResult.E_LICENSE_EXPIRE:
            return "授权文件过期"
        case STIDLivenessResult.E_LICENSE_VERSION_MISMATCH:
            return "License与SDK版本不匹"
        case STIDLivenessResult.E_LICENSE_PLATFORM_NOT_SUPPORTED:
            return "License不支持当前平台"
        case STIDLivenessResult.E_MODEL_INVALID:
            return "模型文件错误"
        case STIDLivenessResult.E_DETECTION_MODEL_FILE_NOT_FOUND:
            return "DETECTION 模型文件不存在"
        case STIDLivenessResult.E_ALIGNMENT_MODEL_FILE_NOT_FOUND:
            return "ALIGNMENT 模型文件不存在"
        case STIDLivenessResult.E_FACE_QUALITY_MODEL_FILE_NOT_FOUND:
            return "FACE_QUALITY 模型文件不存在"
        case STIDLivenessResult.E_FRAME_SELECTOR_MODEL_FILE_NOT_FOUND:
            return "FRAME_SELECTOR 模型文件不存在"
        case STIDLivenessResult.E_ANTI_SPOOFING_MODEL_FILE_NOT_FOUND:
            return "ANTI_SPOOFING 模型文件不存在"
        case STIDLivenessResult.E_MODEL_EXPIRE:
            return "模型文件过期"
        case STIDLivenessResult.E_INVALID_ARGUMENT:
            return "参数设置不合法"
        case STIDLivenessResult.E_TIMEOUT:
            return "检测超时,请重试一次"
        case STIDLivenessResult.E_CALL_API_IN_WRONG_STATE:
            return "错误的方法状态调用"
        case STIDLivenessResult.E_FAILED:
            switch faceError {
            case STIDLivenessFaceError.E_NOFACE_DETECTED:
                return "未检测到人脸，请重新进行检测"
            case STIDLivenessFaceError.E_FACE_CHANGED:
                return "人脸离开了画面，请重新进行检测"
            case STIDLivenessFaceError.E_FACE_UNKNOWN:
                return "未知原因"
            @unknown default:
                return ""
            }
        case STIDLivenessResult.E_CAPABILITY_NOT_SUPPORTED:
            return "授权文件能力不支持"
        case STIDLivenessResult.E_API_KEY_INVALID:
            return "API账户信息错误"
        case STIDLivenessResult.E_SERVER_ACCESS:
            return "服务器访问错误"
        case STIDLivenessResult.E_SERVER_TIMEOUT:
            return "服务器访问超时"
        case STIDLivenessResult.E_HACK:
            return "活体检测未通过"
        case STIDLivenessResult.E_SIGN_FAILED:
            return "数据签名失败，请注意检查lic是否与SDK匹配"
        case STIDLivenessResult.E_UNTRUSTED_RESULT:
            return "数据校验失败，活体检测结果不可信"
        @unknown default:
            return "未知错误"
        }
    }
    
    private func messageStringBycloudInternalCode(result: STIDLivenessCloudInternalCode) -> String{
        switch result {
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_DEFAULT:
            return "内部错误/未知错误"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_SUCCESS:
            return ""
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_API_KEY_MISSING:
            return "api_key值为空"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_INVALID_API_KEY:
            return "无效的api_key"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_API_KEY_IS_DISABLED:
            return "api_key被禁用"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_API_KEY_HAS_EXPIRED:
            return "api_key已过期 "
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_PERMISSION_DENIED:
            return "无该功能权限"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_BUNDLE_ID_MISSING:
            return "bundle_id值为空"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_BUNDLE_ID_IS_DISABLED:
            return "bundle_id被禁用"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_DAILY_RATE_LIMIT_EXCEEDED:
            return "每日调用已达限制"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_APP_SIGN_MISSING:
            return "未传入应用签名"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_INVALID_APP_SIGN:
            return "开发者中心没有配置应用签名"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_INVALID_SIGNATURE:
            return "数据一致性验证失败"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_INVALID_BUNDLE_ID:
            return "bundle_id验证失败"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_INVALID_SN:
            return "无效的sn码"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_REQUEST_HAS_EXPIRED:
            return "请求时间过期"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_DUPLICATE_REQUEST:
            return "重复请求"
        case STIDLivenessCloudInternalCode.CLOUD_INTERNAL_SENSETIME_ERROR:
            return "内部错误，请联系商汤支持人员"
        default:
            return "未知云端错误码"
        }
    }
}

extension FaceManager: STLivenessControllerDelegate{
    func livenessControllerDeveiceError(_ deveiceError: STIDLivenessDeveiceError) {
        switch deveiceError{
        case STIDLivenessDeveiceError.E_CAMERA:
            Toast.showError("相机权限检测失败\n请前往设置－隐私－相机中开启相机权限")
        case STIDLivenessDeveiceError.WILL_RESIGN_ACTIVE:
            Toast.showError("取消检测")
        @unknown default:
            break
        }
        popViewController()
    }
}
