//
//  PayManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/5/15.
//

import UIKit
import WebKit

enum NNPayType: Int {
    case wechat = 9
    case aliPay = 2
    case other
}

class PayManager: NNBaseView {
    private var linkUrl: String?
    private var paymentType: NNPayType = .wechat
    // MARK: Lifecycle
    deinit {
        print("\(#file)" + "\(#function)")
    }
    
    override func nn_initViews() {
        self.backgroundColor = .clear
        self.addSubview(webView)
    }

    func nn_initData(linkUrl: String?, paymentType: NNPayType) {
        self.linkUrl = linkUrl
        self.paymentType = paymentType
        guard let text = linkUrl else { return }
        var request = URLRequest(url: URL(string: text)!)
        if self.paymentType == .wechat {
            let text = "\(ApiConst.WeChat.payUniversalLink)://"
            request.setValue(text, forHTTPHeaderField: "referer")
        }
        webView.load(request)
    }
    
    override func nn_addLayoutSubviews() {
        webView.frame = .zero
    }
    
    // MARK: Public Method
    
    // MARK: Private Method
    
    // MARK: Request Network
    
    // MARK: Event Response
    
    // MARK: Set
    
    // MARK: Get
    private lazy var webView: WKWebView = {
        let jScript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"

        let wkUScript: WKUserScript = WKUserScript(source: jScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let wkUController: WKUserContentController = WKUserContentController()
        wkUController.addUserScript(wkUScript)
        let config = WKWebViewConfiguration()
        config.userContentController = wkUController
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = self
        return view
    }()
}

extension PayManager: WKNavigationDelegate{
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Toast.showInfo("支付异常")
        self.removeFromSuperview()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let payReqUrl = navigationAction.request.url
        log.info("reqUrl.absoluteStrin:\(navigationAction.request.url?.absoluteString ?? "")")
        if var payReqUrl = payReqUrl,
           payReqUrl.absoluteString.hasPrefix("alipays://") || payReqUrl.absoluteString.hasPrefix("alipay://") {
            if let payReqStr = payReqUrl.absoluteString.removingPercentEncoding,
               payReqStr.contains("fromAppUrlScheme\":\"alipays\"") == true,
               let urlStr = payReqStr
                .replacingOccurrences(of: "fromAppUrlScheme\":\"alipays\"", with:  "fromAppUrlScheme\":\"\(ApiConst.WeChat.payUniversalLink)\"")
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: urlStr){
                payReqUrl = url
            }
            
            UIApplication.shared.open(payReqUrl){ bSucc in
                if (!bSucc) {
                    Toast.showInfo("未检测到支付宝客户端，请安装后重试。")
                }
                self.removeFromSuperview()
            }
            decisionHandler(WKNavigationActionPolicy.cancel)
        } else if let reqUrl = payReqUrl,
                  reqUrl.absoluteString.hasPrefix("weixin://wap/pay") {
            UIApplication.shared.open(reqUrl){ bSucc in
                if (!bSucc) {
                    Toast.showInfo("未检测到微信客户端，请安装后重试。")
                }
                self.removeFromSuperview()
            }
            decisionHandler(WKNavigationActionPolicy.cancel)
        } else {
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }
}


