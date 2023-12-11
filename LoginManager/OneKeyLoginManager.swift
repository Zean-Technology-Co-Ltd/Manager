//
//  OneKeyLoginManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/5/16.
//

import UIKit
import ATAuthSDK

public let PNSCodeSuccess = "600000"
private let PNSCodeLoginControllerPresentSuccess = "600001"
private let PNSCodeLoginControllerPresentFailed = "600002"
private let PNSCodeGetOperatorInfoFailed = "600004"
private let PNSCodeNoSIMCard = "600007"
private let PNSCodeNoCellularNetwork = "600008"

private let PNSCodeLoginControllerClickCancel = "700000"
private let PNSCodeLoginControllerClickChangeBtn = "700001"
private let PNSCodeLoginControllerClickLoginBtn = "700002"
private let PNSCodeLoginControllerClickCheckBoxBtn = "700003"
private let PNSCodeLoginControllerClickProtocol = "700004"
private let PNSCodeLiftBodyVerifyReadyStating = "700005"

class OneKeyLoginManager: NSObject {
    private var showVc: UIViewController?
    static func register(){
        TXCommonHandler.sharedInstance().setAuthSDKInfo(ApiConst.ServiceKey.ALILoginSecretkey) { resultDic in
            log.info("resultDic:\(resultDic)")
        }
    }
    
    static let `default`: OneKeyLoginManager = {
        return OneKeyLoginManager()
    }()
    
    public func setup(showVC vc: UIViewController){
        self.showVc = vc
    }
    
    public func loginWithBack(successBlock: @escaping ((_ token: String)->()), failBlock:((String)->())?){
        // 使用预登录取号
        TXCommonHandler.sharedInstance().checkEnvAvailable(with: PNSAuthType.loginToken) { [weak self] resultDic in
            log.info("checkEnvAvailable:\(resultDic as Any)")
            if let code = resultDic?["resultCode"] as? String,
               (PNSCodeSuccess == code) == false {
                failBlock?(code)
                return
            }
            // 设置登录授权页面UI
            guard let `self` = self else { return }
            TXCommonHandler.sharedInstance().accelerateLoginPage(withTimeout: 5) { [weak self] resultDic in
                if let code = resultDic["resultCode"] as? String,
                   (PNSCodeSuccess == code) == false {
                    failBlock?(code)
                    return
                }
                guard let `self` = self else { return }
                let controller = self.showVc ?? self.topmostViewController
                TXCommonHandler.sharedInstance().getLoginToken(withTimeout: 5, controller: controller!, model: self.setUImodel()) { resultDic in
                    guard let code = resultDic["resultCode"] as? String else { return }
                    if PNSCodeLoginControllerPresentFailed == code {
                        Toast.showError("无法进行一键登录")
                        failBlock?(code)
                        return
                    }
                    if PNSCodeLoginControllerPresentSuccess == code ||
                        PNSCodeLoginControllerClickCancel == code ||
                        PNSCodeLoginControllerClickCheckBoxBtn == code ||
                        PNSCodeLoginControllerClickProtocol == code {
                    } else if PNSCodeLoginControllerClickChangeBtn == code {
                        TXCommonHandler.sharedInstance().cancelLoginVC(animated: true)
                    } else if PNSCodeLoginControllerClickLoginBtn == code {
                        log.info(resultDic["isChecked"] as Any)
                        if let isChecked = resultDic["isChecked"] as? Bool,
                           isChecked == false {
                            Toast.showInfo("请仔细阅读《用户协议》和《隐私协议》并勾选同意")
                        }
                    } else if PNSCodeSuccess == code {
                        if let token = resultDic["token"] as? String,
                           String.isEmpty(token) == false {
                            successBlock(token)
                        } else {
                            TXCommonHandler.sharedInstance().cancelLoginVC(animated: true)
                            Toast.showInfo("暂不支持一键登录")
                        }
                    } else {
                        TXCommonHandler.sharedInstance().cancelLoginVC(animated: true)
                        Toast.showInfo("获取登录Token失败")
                    }
                }
            }
        }
    }
    
    
    
    fileprivate func setUImodel() -> TXCustomModel{
        let uiModel = TXCustomModel()
        uiModel.backgroundColor = .white
        /**弹出方式*/
        uiModel.supportedInterfaceOrientations = UIInterfaceOrientationMask.portrait
        /**隐藏导航栏*/
        uiModel.navIsHidden = true
        /**logo的图片设置*/
        uiModel.logoImage = R.image.common_logo()!
        uiModel.logoFrameBlock = { (screenSize, superViewSize, frame) in
            return CGRectMake(UIScreen.screenWidth * 0.5 - 38, 220.rpx(), 76, 76)
        }
        let sloganDict = [NSAttributedString.Key.foregroundColor: UIColor.c1A1A1A, NSAttributedString.Key.font: UIFont.regular(20)]
        uiModel.sloganText = NSAttributedString(string: UIDevice.appName, attributes: sloganDict)
        uiModel.sloganFrameBlock = { (screenSize, superViewSize, frame) in
            var frame = frame
            frame.origin.y = 220.rpx() + 90
            return frame
        }
        /**手机号码相关设置*/
        uiModel.numberFont = UIFont.medium(16)
        uiModel.numberColor = .c1A1A1A
        uiModel.numberFrameBlock = { (screenSize, superViewSize, frame) in
            var frame = frame
            frame.origin.y = 220.rpx() + 90 + 30
            return frame
        }
        uiModel.changeBtnTitle = NSAttributedString(string: "验证码登录", attributes: [NSAttributedString.Key.foregroundColor: UIColor.themeColor, NSAttributedString.Key.font: UIFont.medium(16)])
#if DEBUG
        uiModel.changeBtnIsHidden = false //切换登录方式
#else
        uiModel.changeBtnIsHidden = true
#endif
        
        /**登录按钮相关*/
        uiModel.loginBtnText = NSAttributedString(string: "本机号码一键登录", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.medium(18)])
        //可以使用图片方法实现登录按钮圆角 loginBtnImgs model.logBtnImgs = @[norMal,invalied,highted];
        uiModel.loginBtnBgImgs = [R.image.common_btn_bkg_image()!, R.image.common_btn_bkg_image()!, R.image.common_btn_bkg_image()!]
        uiModel.loginBtnFrameBlock = { (screenSize, superViewSize, frame) in
            return CGRectMake(29, 360.rpx() + 120, UIScreen.screenWidth - 59, 50)
        }
        /**底部协议复选框设置*/
        uiModel.checkBoxIsHidden = false
        uiModel.checkBoxWH = 16
        uiModel.expandAuthPageCheckedScope = true
        uiModel.checkBoxImageEdgeInsets = .zero
        uiModel.checkBoxImages = [R.image.common_agreement_unselect()!, R.image.common_agreement_select()!]
        uiModel.privacyOne = ["《注册协议》", "\(ApiConst.APIKey.appstoreURL)/pages/register.html"]
        uiModel.privacyTwo = ["《隐私协议》", "\(ApiConst.APIKey.appstoreURL)/pages/privacy.html"]
        uiModel.privacyOperatorPreText = "《"
        uiModel.privacyOperatorSufText = "》"
        uiModel.privacyColors = [UIColor.c1A1A1A, UIColor.themeColor];
        uiModel.privacyPreText = "登录即代表同意"
        uiModel.privacySufText = "并授权获得号码"
        uiModel.privacyFont = .regular(12)
        uiModel.privacyAlignment = NSTextAlignment.center
        uiModel.privacyNavBackImage =  R.image.common_arrow_pop_icon()! //协议弹出页面返回键
        uiModel.privacyFrameBlock = { (screenSize, superViewSize, frame) in
            var frame = frame
            frame.origin.y = 360.rpx() + 190
            return frame
        }
        return uiModel
    }
}

