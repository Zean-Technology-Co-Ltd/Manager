//
//  WeChatManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/5/11.
//

import UIKit

class WeChatManager: NSObject {
    static func register(){
//        WXApi.startLog(by: WXLogLevel.detail) { msg in
//            log.info("WXLogLevel\(msg)")
//        }
        WXApi.registerApp(NNApiConst.WeChat.appID, universalLink: NNApiConst.WeChat.universalLink)
//        WXApi.checkUniversalLinkReady { step, result in
//            log.info("step:\(step)")
//            log.info("result.success:\(result.success)")
//            log.info("result.errorInfo:" + result.errorInfo)
//            log.info("result.suggestion:" + result.suggestion)
//        }
    }
    
    static let `default`: WeChatManager = {
        return WeChatManager()
    }()
    
    class func canOpen()-> Bool{
        return WXApi.openWXApp()
    }
    
    /// 支付
    class func miniProgramPayReq(_ repaymentSn: String, payAmount: String) -> WXLaunchMiniProgramReq{
        let launchMiniProgramReq = WXLaunchMiniProgramReq.object()
        launchMiniProgramReq.userName = NNApiConst.WeChat.miniProgramName;
        launchMiniProgramReq.path = "pages/money/payBill?repaymentSn=\(repaymentSn)&payAmount=\(payAmount)";
#if DEBUG
        launchMiniProgramReq.miniProgramType = WXMiniProgramType.test //拉起小程序的类型
#else
        launchMiniProgramReq.miniProgramType = WXMiniProgramType.release //拉起小程序的类型
#endif
        return launchMiniProgramReq
    }
    
    /// 客服
    class func miniProgramReq() -> WXLaunchMiniProgramReq?{
        let launchMiniProgramReq = WXLaunchMiniProgramReq.object()
        launchMiniProgramReq.userName = NNApiConst.WeChat.miniProgramName;
        launchMiniProgramReq.path = NNApiConst.WeChat.miniProgramPath;
#if DEBUG
        launchMiniProgramReq.miniProgramType = WXMiniProgramType.test //拉起小程序的类型
#else
        launchMiniProgramReq.miniProgramType = WXMiniProgramType.release //拉起小程序的类型
#endif
        return launchMiniProgramReq
    }
    
    class func share()-> SendMessageToWXReq{
        let webpageObject = WXWebpageObject()
        webpageObject.webpageUrl = NNApiConst.WeChat.webpageUrl
        let message = WXMediaMessage()
        message.title = NNApiConst.WeChat.appName;
        message.description = NNApiConst.WeChat.description
        message.setThumbImage(R.image.common_logo()!)
        message.mediaObject = webpageObject
        let req = SendMessageToWXReq()
        req.bText = false
        req.message = message
        req.scene = Int32(WXSceneSession.rawValue)
        return req
    }
    
}
