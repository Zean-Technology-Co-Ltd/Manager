//
//  PostDataDTO.swift
//  WKWebViewDemo
//
//  Created by Alan Ge on 2023/7/9.
//

import Foundation
import RxSwift
import Moya

class PostDataDTO {
    static var shared = PostDataDTO()
    private let provider = Request<TBApi>()
    private let disposeBag = DisposeBag()
    private let currentUserId = "\(Authorization.default.user?.id ?? "")_\(NSObject.Tenant)"
    
    func postData(path: String, content: String, type: String? = nil, month: String? = nil) {
        var parameters = ["currentUserId": self.currentUserId,
                          "body": content]
        if let type = type {
            parameters["type"] = type
        }
        if let month = month {
            parameters["month"] = month
        }
        postData(path: path, parameters: parameters)
    }
    
    func postData(path: String, parameters: [String: Any]) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let `self` = self else { return }
            self.provider
                .rx
                .request(objectTarget: .uploadData(path: path, parameters: parameters),
                                mapType: TBResponseModel.self)
                .subscribe(onNext: { model in
                    print("path:\(path) \nparameters:\(parameters)")
                })
                .disposed(by: disposeBag)
        }
    }
    
    func DataToObject(_ data: Data) -> Any? {
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            return object
        } catch {
            log.info(error)
        }
        return nil
    }
}

struct TBResponseModel: Codable {}


enum TBApi {
    case uploadData(path: String, parameters: [String: Any])
}

extension TBApi: RequestTargetType {
    
    var cachePolicy: RequestCachePolicy {
        return .none
    }
    
    var authorizationType: AuthorizationType {
        return .none
    }
    
    var baseURL: URL {
        return URL(string: "http://106.13.235.245/")!
    }
    
    var shouldAuthorize: Bool {
        return true
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var sampleData: Data {
        return Data()
    }

    var task: Task {
        return .requestParameters(parameters: parameters!, encoding: ReplaceQuestionMarkPostEncoding())
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var path: String{
        switch self {
        case let .uploadData(path, _):
            return "\(path)"
        }
    }
    
    var parameters: [String: Any]?{
        switch self {
        case let .uploadData(_, parameters):
            return parameters
        }
    }
    
}
