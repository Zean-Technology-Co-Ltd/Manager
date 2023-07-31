//
//  OCRManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/6/26.
//

import UIKit
import AVFoundation

class OCRManager: NSObject {
    private var type: STIDCardQualityScanType = STIDCardQualityScanType.front
    private var callback: ((_ image: UIImage, _ name: String, _ idCard: String)->())?
    private var idCardDataCallback: ((Data)->())?
    private var writeManager: AVAssetWriteManager?
    private let lock = NSLock()
    private var videoUrl: URL?
    
    static let `default`: OCRManager = {
        return OCRManager()
    }()
    
    func ocr(_ type: STIDCardQualityScanType, superVC: UIViewController, callback:@escaping ((_ image: UIImage, _ name: String, _ idCard: String)->()), idCardDataCallback: @escaping ((Data)->())){
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .restricted || authStatus == .denied {
            Toast.showInfo("相机权限获取失败:请在设置-隐私-相机中开启后重试")
            return;
        }
        self.idCardDataCallback = idCardDataCallback
        self.callback = callback
        self.type = type
        let vc = STIDCardQualityContainerViewController()
        vc.scanType = type
        vc.enableRestart = OCRData.isNeedReStart
        vc.delegate = self
        superVC.navigationController?.pushViewController(vc, animated: true)
        
        self.videoUrl = URL(fileURLWithPath: self.filePath())
        self.writeManager = AVAssetWriteManager()
        self.writeManager?.startWrite(videoUrl)
    }
    // MARK: Private Method
    private func endAssetWrite(){
        self.writeManager?.stopWrite()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.writeManager?.getVideoData { [weak self] data in
                if let data = data {
                    self?.idCardDataCallback?(data)
                }
            }
            self?.writeManager?.destroyWrite()
        }
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
    private lazy var OCRData: STIDOCRSettingGLobalData = {
        return STIDOCRSettingGLobalData.sharedInstance()
    }()
}

extension OCRManager: STIDCardQualityScannerControllerDelegate{
    func nn_captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
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
    
    func detectorInitSuccess(_ idCardQualityDetector: STIDCardQualityDetector!) {
        /// 不完整程度，取值范围为0-1，默认值0.5，得分越低，说明卡片在图片中越完整。区别于遮挡，此处不完整是指卡片边界没有全部出现在图片中
        idCardQualityDetector.setIncompleteThreshold(0.1)
        idCardQualityDetector.setDimLightThreshold(CGFloat(OCRData.dimLightThreshold))
        idCardQualityDetector.setHighLightThreshold(CGFloat(OCRData.highLightThreshold))
        /// 模糊度，取值范围为0-1，默认值0.8，得分越低，图片越清晰
        idCardQualityDetector.setBlurryThreshold(CGFloat(0.1))
        /// occludedThreshold 遮挡，取值范围为0-1，默认值0.5，得分越低，卡片被遮挡的概率越低。区别于不完整度，此处遮挡指卡片的卡面、关键信息被其他物体遮挡
        idCardQualityDetector.setOccludedThreshold(0.1)
        idCardQualityDetector.setNormalThreshold(CGFloat(OCRData.normalThreshold))
        idCardQualityDetector.setTimeout(Int(OCRData.detectTimeout))
    }
    
    func idCardScanSuccess(with cardInfo: STIDCardQualityCardInfo!, cloudInfo: STIDCardQualityCloudInfo!) {
        if self.type == .front {
#if DEBUG
            self.callback?(cardInfo.originalFrontImage().image, cardInfo.name(), cardInfo.number())
#else
            if cardInfo.frontImageClassify() == STIDCardQualityImageClassify.normal {
                self.callback?(cardInfo.originalFrontImage().image, cardInfo.name(), cardInfo.number())
            } else {
                Toast.showInfo("请扫描身份证原件")
            }
#endif
        } else {
#if DEBUG
            self.callback?(cardInfo.originalBackImage().image, cardInfo.name(), cardInfo.number())
#else
            if cardInfo.backImageClassify() == STIDCardQualityImageClassify.normal {
                self.callback?(cardInfo.originalBackImage().image, cardInfo.name(), cardInfo.number())
            } else {
                Toast.showInfo("请扫描身份证原件")
            }
#endif
        }
        self.endAssetWrite()
    }
    
    func idCardScanFailure(withResultMsg resultMsg: String!, cloudMsg: String!) {
        if !String.isEmpty(resultMsg) && !String.isEmpty(cloudMsg) {
            Toast.showError("\(resultMsg ?? "")\n\(cloudMsg ?? "")")
        } else if !String.isEmpty(resultMsg) {
            Toast.showError(resultMsg)
        } else if !String.isEmpty(cloudMsg) {
            Toast.showError(cloudMsg)
        }
        self.endAssetWrite()
    }
    
    func idCardReceive(_ deveiceError: STIDOCRIDCardQualityDeveiceError) {
        switch deveiceError{
        case STIDOCRIDCardQualityDeveiceError.E_CAMERA:
            Toast.showInfo("相机权限检测失败\n请前往设置－隐私－相机中开启相机权限")
        case STIDOCRIDCardQualityDeveiceError.WILL_RESIGN_ACTIVE:
            Toast.showInfo("取消检测")
        @unknown default:
            break
        }
        self.writeManager?.destroyWrite()
    }
}
