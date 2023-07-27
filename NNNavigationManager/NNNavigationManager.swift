//
//  NNNavigationManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/4/24.
//

import UIKit
import RxSwift
import Moya
import Result

enum NNSwitchRootType {
    case login(AuthorizedWrapper?)
    case loginOut
    case main
}

class NNNavigationManager: NSObject, RequestAuthorizationPluginUpdate, AccessTokenUpdate, RequestUnAuthorisedProcess {
    
    fileprivate var rootType: NNSwitchRootType?
    private var rootDisposeBag: DisposeBag!
    static let sharedInstance = NNNavigationManager()
    private var window: UIWindow?
    deinit {
        
    }
    
    private override init() {
        super.init()
        register(unAuthorisedProcessor: self)
    }
    
    func switchRoot(_ type: NNSwitchRootType, window: UIWindow? = UIApplication.shared.keyWindow) {
        if self.window == nil {
            self.window = window
        }
        rootDisposeBag = nil
        rootDisposeBag = DisposeBag()
        
        switch type {
        case .main:
            let rootVc = NNAppearanceProvider.customStyle()
            rootVc.selectedIndex = 0
            self.window!.rootViewController = rootVc
        case .loginOut:
            switch self.rootType {
            case .main:
                self.deleteAuthorizedWrapper()
                self.updatePlugin(token: nil)
                self.switchRoot(.login(nil))
            default :
                break
            }
        case .login:
            let rootVc = NNLoginViewController()
            rootVc.reactor = NNLoginViewModel()
            rootVc.login = {[weak self] wrapper in
                if let wrapper = wrapper, let `self` = self {
                    self.updateAuthorizedWrapper(wrapper)
                    self.updatePlugin(token: wrapper.token?.access_token)
                    self.switchRoot(.main)
                }
            }
            self.window!.rootViewController = UINavigationController(rootViewController: rootVc)
        }
        
        self.rootType = type
    }
    func processUnAuthorisedResponse(_ response: RequestResponse?, message: String?) -> Result<Moya.Response, Moya.MoyaError>? {
        switch self.rootType {
        case .main:
            delay(time: 1) {
                DispatchQueue.main.async(execute: {
                    self.switchRoot(.loginOut)
                })
            }
            return Result.failure(MoyaError.requestMapping("登录失效，请重新登录"))
        default:
            return nil
        }
    }
}
