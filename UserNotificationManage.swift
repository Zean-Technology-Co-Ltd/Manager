//
//  UserNotificationManage.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/6/21.
//

import UIKit

class UserNotificationManage: NSObject {
    let privoder = Request<NotificationApi>()
    static let `default`: UserNotificationManage = {
        return UserNotificationManage()
    }()

    func notification(noti: [AnyHashable : Any], taskId: String?){
        if self.topmostViewController is NNOrderListVC {
           
        } else {
            self.topmostViewController?.navigationController?.pushViewController(NNOrderListVC(type: .all)
                                                                                 , animated: true)
        }
        
        if let taskId = taskId {
            self.privoder
                .rx
                .request(objectTarget: NotificationApi.getuiAck(taskId), mapType: NNBaseModel.self)
                .subscribe(onNext: { _ in
                }).disposed(by: rx.disposeBag)
        }
    }
}


import Moya

enum NotificationApi {
   /// 个推
    case getuiAck(String)
}

extension NotificationApi: RequestTargetType {
    
    var cachePolicy: RequestCachePolicy {
        return .none
    }
    
    var authorizationType: AuthorizationType {
        return .none
    }
    
    var baseURL: URL {
        return URL(string: ApiConst.APIKey.serverURL)!
    }
    
    var shouldAuthorize: Bool {
        return true
    }
    
    var method: Moya.Method {
        return .put
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        return .requestParameters(parameters: parameters!, encoding: MultipleEncoding())
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var path: String{
        switch self {
        case .getuiAck(let id):
            return "mall-sms/app-api/v1/collect/getui/\(id)/ack"
        }
    }
    
    var parameters: [String: Any]?{
        return [String: Any]()
    }
    
}
