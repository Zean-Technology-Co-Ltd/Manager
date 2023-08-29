//
//  TaoBaoAuthorizedManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/6/16.
//  参考资料 https://cloud.tencent.com/developer/ask/sof/87370
// https://www.cnblogs.com/lxlx1798/articles/14259055.html
/**
    清除WKWebView的缓存
    在磁盘缓存上。
    WKWebsiteDataTypeDiskCache,
    
    html离线Web应用程序缓存。
    WKWebsiteDataTypeOfflineWebApplicationCache,
    
    内存缓存。
    WKWebsiteDataTypeMemoryCache,
    
    本地存储。
    WKWebsiteDataTypeLocalStorage,
    
    Cookies
    WKWebsiteDataTypeCookies,
    
    会话存储
    WKWebsiteDataTypeSessionStorage,
    
    IndexedDB数据库。
    WKWebsiteDataTypeIndexedDBDatabases,
    
    查询数据库。
    WKWebsiteDataTypeWebSQLDatabases
    */
import UIKit
import WebKit

enum TBAuthorizedType {
    case password
    case qrcode
    case smsCode
}

class TaoBaoAuthorizedManager: NNBaseView {
    private var callback: ((Bool)->Void)?
    private var loginType: TBAuthorizedType = .qrcode
    public var cookieArray: [HTTPCookie] = []
    public var storage: HTTPCookieStorage {
        let storage = HTTPCookieStorage.shared
        storage.cookieAcceptPolicy = .always
        return storage
    }
    public var trackId = "\(Date.todayTimestamp)"
    public var actionType = "我的淘宝"
    public var userId = "\(Authorization.default.user?.id ?? "")_\(NSObject.Tenant)"
    public var getAddress = false
    public var zhifubao = true
    public var taobaoHttp = true
    public var aliIndex = false
    public var scanNum = 0
    public let getHtmlJS = "var url = window.location.href;" +
    "var body = document.getElementsByTagName('html')[0].outerHTML;" +
    "var data = {\"url\":url,\"responseText\":body};" +
    "window.webkit.messageHandlers.showHtml.postMessage(data);"
    private let myUA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    // MARK: Lifecycle
    deinit {
        log.info("TaoBaoAuthorizedManager\(#file)" + "\(#function)")
        
    }
    
    convenience init(loginType: TBAuthorizedType = .qrcode,callback: @escaping ((Bool)->Void)) {
        self.init()
        self.loginType = loginType
        self.callback = callback
    }
    
    override func nn_initViews (){
        removeALLWebsiteDataStore()
    }
    
    private func initViews (){
        self.addSubview(webView)
    }
    
    private func initDatas() {
        let linkUrl = "https://login.taobao.com/"
        var request =  URLRequest(url: URL(string: linkUrl)!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.setValue("User-Agent", forHTTPHeaderField: myUA)
        webView.load(request)
        if self.loginType == .qrcode {
            HUD.wait(info: "跳转中...")
        }
    }
    
    private func addLayoutSubviews (){
#if DEBUG
        webView.frame = UIScreen.screenBounds
#else
        webView.frame = .zero
#endif
       
    }
    // MARK: Event Response
    // MARK: Public Method
    public func updateAccount(account: String){
        if loginType != .password { return }
        let accountJs = "document.querySelector(\"#fm-login-id\").value = " + "'\(account)'"
        self.evaluateJavaScript(accountJs)
    }
    
    public func updatePassword(password: String){
        if loginType != .password { return }
        let passwordJs = "document.querySelector(\"#fm-login-password\").value = " + "'\(password)'"
        self.evaluateJavaScript(passwordJs)
    }
    
    public func loginWithPassword(){
        if loginType != .password { return }
        HUD.wait(info: "授权中...")
        let loginJs = "document.querySelector(\"#login-form > div.fm-btn > button\").click()"
        self.evaluateJavaScript(loginJs)
    }
    
    public func updateMobile(mobile: String){
        if loginType != .smsCode { return }
        let mobileJs = "document.querySelector(\"#fm-sms-login-id\").value = " + mobile
        self.evaluateJavaScript(mobileJs)
    }
    
    public func updateSmsCode(smsCode: String){
        if loginType != .smsCode { return }
        let verificationCodeJs = "document.querySelector(\"#fm-smscode\").value = " + smsCode
        self.evaluateJavaScript(verificationCodeJs)
    }

    public func sendVerificationCode(){
        if loginType != .smsCode { return }
        let loginJs = "document.querySelector(\"#login-form > div.fm-field.fm-field-sms > div.send-btn > a\").click()"
        self.evaluateJavaScript(loginJs)
    }
    
    public func loginWithVerificationCode(){
        if loginType != .smsCode { return }
        HUD.wait(info: "授权中...")
        let loginJs = "document.querySelector(\"#login-form > div.fm-btn > button\").click()"
        self.evaluateJavaScript(loginJs)
    }
    
    public func updateLoginType(type: TBAuthorizedType){
        self.loginType = type
        if type == .password {
            let loginJs = "document.querySelector(\"#login > div.login-content.nc-outer-box > div > div.login-blocks.login-switch-tab > a.password-login-tab-item\").click()"
            self.evaluateJavaScript(loginJs)
        } else if type == .smsCode{
            let loginJs = "document.querySelector(\"#login > div.login-content.nc-outer-box > div > div.login-blocks.login-switch-tab > a.sms-login-tab-item\").click()"
            self.evaluateJavaScript(loginJs)
        }
    }
    
    // MARK: Private Method
    private func removeALLWebsiteDataStore(){
        let store: WKWebsiteDataStore = WKWebsiteDataStore.default()
        let dataTypes: Set<String> = WKWebsiteDataStore.allWebsiteDataTypes()
        store.fetchDataRecords(ofTypes: dataTypes, completionHandler: { [weak self] (records: [WKWebsiteDataRecord]) in
            store.removeData(ofTypes: dataTypes, for: records, completionHandler: {})
            self?.initViews()
            self?.initDatas()
            self?.addLayoutSubviews()
        })
    }
    
    private func removeSomeWebsiteDataStore(){
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = NSDate(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date as Date, completionHandler:{ })
    }
    
    // MARK: Set
    
    // MARK: Get
    internal lazy var webView: WKWebView = {
        let wkUController: WKUserContentController = WKUserContentController()
        wkUController.add(self, name: "ajaxDone")
        wkUController.add(self, name: "showHtml")
        wkUController.add(self, name: "upMyZfbInfo")
        wkUController.add(self, name: "upBill")
        wkUController.add(self, name: "tbAuthenticationName")
        wkUController.add(self, name: "trackTbUrl")
        let config = WKWebViewConfiguration()
        config.userContentController = wkUController
        let view = WKWebView(frame: .zero, configuration: config)
        view.customUserAgent = myUA
        view.navigationDelegate = self
        return view
    }()
}

extension TaoBaoAuthorizedManager: WKScriptMessageHandler{
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "ajaxDone",
           let dic = message.body as? [String: Any],
           let body = dic["responseText"] as? String {
            ajaxDone(body: body)
        } else if message.name == "showHtml",
                  let dic = message.body as? [String: Any],
                  let body = dic["responseText"] as? String {
            let url = dic["url"] as? String
            showHtml(url: url, body: body)
        } else if message.name == "upMyZfbInfo",
                  let dic = message.body as? [String: Any] {
            let url = dic["url"] as? String
            let t1 = dic["t1"] as? String
            let t2 = dic["t2"] as? String
            let type = dic["type"] as? Int
            upMyZfbInfo(url: url, t1: t1 ?? "", t2: t2 ?? "", type: type ?? 0)
        } else if message.name == "upBill",
                  let dic = message.body as? [String: Any],
                  let url = dic["url"] as? String {
            let body = dic["responseText"] as? String
            let currMonth = dic["currMonth"] as? Int
            upBill(url: url, body: body ?? "", sizeMonth: "\(currMonth ?? 0)")
        } else if message.name == "tbAuthenticationName",
                  let dic = message.body as? [String: Any],
                  let name = dic["name"] as? String,
                  let idCard = dic["idCard"] as? String{
            let url = dic["url"] as? String
            tbAuthenticationName(url: url, name: name, idCard: idCard)
        } else if message.name == "trackTbUrl",
                  let dic = message.body as? [String: Any],
                  let html = dic["html"] as? String{
            let url = dic["url"] as? String
            trackTbUrl(url: url ?? "", html: html)
        }
    }
    
    func ajaxDone(body: String) {
        let content = body.toDictionary()
        if let content = content?["content"] as? [String: Any] {
            if let data = content["data"] as? [String: Any],
               let ck = data["ck"] as? String {
                HUD.wait(info: "授权中...")
                let linkUrl = "taobao://login.taobao.com/qrcodeCheck.htm?lgToken=\(ck)&tbScanOpenType=Notification"
                UIApplication.shared.open(URL(string: linkUrl)!)
            }
        }
    }
}

extension TaoBaoAuthorizedManager: WKNavigationDelegate{
  
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let absoluteString = webView.url?.absoluteString
        if loginType == .qrcode {
            self.clickTBQrcode(webView: webView)
        }
    
        log.debug("webViewDidFinish:\(absoluteString ?? "")")
        // [步骤1]，扫码成功后，进入了淘宝首页
        DispatchQueue.global().async { [weak self] in
            if absoluteString?.hasPrefix("https://i.taobao.com/my_taobao.htm") == true {
                self?.actionType = "我的淘宝"
                if self?.getAddress == true {
                    self?.actionType = "跳转支付宝"
                    Thread.sleep(forTimeInterval: 0.1)
                    // 所有操作都完成后，进行跳转支付宝
                    let removeBlankJS = "var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','_self');}"
                    
                    self?.evaluateJavaScript(removeBlankJS )
                    Thread.sleep(forTimeInterval: 0.5)
                    
                    let gotoAliJS = "document.getElementById(\"J_MyAlipayInfo\").getElementsByTagName(\"a\")[1].click()"
                    self?.evaluateJavaScript(gotoAliJS)
                } else {
                    DispatchQueue.main.async { [weak self] in
                        // 协议获取淘宝个人信息
                        self?.loginSuccess(webView: webView, absoluteString: absoluteString)
                        // 协议获取订单信息
                        self?.getOrders(webView: webView, absoluteString: absoluteString)
                        // [步骤2] 跳转到收货地址信息
                        self?.getAddress(webView: webView, absoluteString: absoluteString)
                        HUD.clear()
                        self?.callback?(true)
                    }
                }
            }
            // 获取我的足迹
            self?.getTbfoot(webView: webView, absoluteString: absoluteString)
            // 返回淘宝首页
            self?.getTbHome(webView: webView, absoluteString: absoluteString)
            //
            self?.getWSMsg(webView: webView, absoluteString: absoluteString)
            self?.getWSHome(webView: webView, absoluteString: absoluteString)
            self?.getWSRepayHome(webView: webView, absoluteString: absoluteString)
            self?.getWSRepayRecord(webView: webView, absoluteString: absoluteString)
            self?.getSwitchPersonal(webView: webView, absoluteString: absoluteString)
            self?.getZFBAccount(webView: webView, absoluteString: absoluteString)
            self?.needAliPayLogin(webView: webView, absoluteString: absoluteString)
            self?.getYebPurchase(webView: webView, absoluteString: absoluteString)
            self?.getRecordStandard(webView: webView, absoluteString: absoluteString)
            self?.getAliBaseMsg(webView: webView, absoluteString: absoluteString)
            self?.getÅssetBankList(webView: webView, absoluteString: absoluteString)
            self?.getAlipayError(webView: webView, absoluteString: absoluteString)
            self?.getCheckSecurity(webView: webView, absoluteString: absoluteString)
            self?.getTBHtml()
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.actionType = "错误日志"
        trackTbUrl(url: webView.url?.absoluteString ?? "", html: error.localizedDescription)
    }
    
    public func trackTbUrl(url: String, html: String){
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            let property = ["html": html,
                            "url": url,
                            "msg": self.actionType,
                            "trackId": self.trackId,
                            "userId": self.userId
            ]
            TrackManager.default.track(.TBErrorMessage, property: property)
        }
    }
}
