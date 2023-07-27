//
//  GTManager.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/6/21.
//  https://dev.getui.com/dev/#/single-product/hISz0KWFqV5UcfCbtOPvx5/dos/statistics/351843721432572/pushRecord/notifyPushRecord

import UIKit
import GTSDK

class GTManager: NSObject {
    /// 设置别名
    class func bindAlias(){
        if let memberId = Authorization.default.token?.memberId{
            GeTuiSdk.bindAlias(memberId, andSequenceNum: "seq-1")
        }
    }

    /// 解绑别名
    class func unbindAlias(){
        if let memberId = Authorization.default.token?.memberId{
            GeTuiSdk.unbindAlias(memberId, andSequenceNum: "seq-1", andIsSelf: true)
        }
    }
}
