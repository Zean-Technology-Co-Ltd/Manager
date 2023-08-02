//
//  TrackType.swift
//  NiuNiuRent
//
//  Created by Q Z on 2023/5/30.
//

import UIKit

enum TrackType: String {
    /// 应用启动
    case MPLaunch = "MPLaunch"
    /// 应用被唤醒
    case MPShow = "MPShow"
    /// 应用被挂起
    case MPHide = "MPHide"
    /// 进入页面
    case MPViewScreen = "MPViewScreen"
    /// 应用分享
    case MPShare = "MPShare"
    /// 按钮点击
    case MPClick = "MPClick"
    /// 收藏
    case MPAddFavorites = "MPAddFavorites"
    /// 离开页面
    case MPPageLeave = "MPPageLeave"
    /// 登录
    case TrackSignup = "TrackSignup"
    /// 页面进入查看审核结果
//    case FindingsOfAudit = "FindingsOfAudit"
    /// 点击取消碎屏
//    case LongPressToClose = "LongPressToClose"
    /// 点击规格
    case ClickOnSpecifications = "ClickOnSpecifications"
    /// 点击服务
    case ClickProductService = "ClickProductService"
    /// 点击售后
    case ClickOnAfterSalesService = "ClickOnAfterSalesService"
    /// 页面进入人脸识别
    case FaceOnLoad = "FaceOnLoad"
    /// 人脸识别超时
    case FaceRecognitionTimeout = "FaceRecognitionTimeout"
    /// 人脸识别成功
    case FaceRecognitionSuccessful = "FaceRecognitionSuccessful"
    /// 人脸识别取消
    case FaceRecognitionCancellation = "FaceRecognitionCancellation"
    /// 实名认证页面进入
    case LoadRealname = "LoadRealname"
    /// 实名认证-应用切至后台
    case UnloadWhenRealAuth = "UnloadWhenRealAuth"
    /// 实名认证点击保存
    case ClickRealNameSubmitAuthenticationSaved = "ClickRealNameSubmitAuthenticationSaved"
    /// 证件上传点击保存
    case UploadHasBeenClickedToSave = "UploadHasBeenClickedToSave"
    /// 开始填写收货人
    case FocusConsigneeName  = "FocusConsigneeName"
    /// 结束填写收货人
    case BlurConsigneeName = "BlurConsigneeName"
    /// 开始填写详细地址
    case FocusDetailAddress = "FocusDetailAddress"
    /// 结束填写详细地址
    case BlurDetailAddressValue = "BlurDetailAddressValue"
    /// 粘贴详细地址
    case CopyDetailAddress = "CopyDetailAddress"
    /// 手机号开始填写
//    case PhoneStartWrite = "PhoneStartWrite"
    /// 手机号填写至7位
//    case PhoneStartWriteSeven = "PhoneStartWriteSeven"
    /// 手机号填写完成
//    case PhoneEndWrite = "PhoneEndWrite"
    /// 身份证号开始填写
    case CardNoStartWrite = "CardNoStartWrite"
    /// 身份证号填写6位
    case CardNoWriteSix = "CardNoWriteSix"
    /// 身份证号填写14位
    case CardNoWriteFourteen = "CardNoWriteFourteen"
    /// 身份证号完成填写
    case CardNoWriteFinish = "CardNoWriteFinish"
    /// 开始发现蓝牙设备列表
    case StartBluetoothDevicesDiscovery = "StartBluetoothDevicesDiscovery"
    /// 蓝牙设备列表
    case GetBluetoothDevices = "GetBluetoothDevices"
    /// 蓝牙适配器状态变化
    case BluetoothAdapterStateChange = "BluetoothAdapterStateChange"
    /// 设备内存信息
    case GetMemoryInfo = "GetMemoryInfo"
    /// 陀螺仪检测
    case Gyroscope = "Gyroscope"
    /// 开始填写工作单位
    case FocusCompanyValue = "FocusCompanyValue"
    /// 工作单位填写事件
    case CompanyWriting = "CompanyWriting"
    /// 结束填写工作单位
    case BlurCompanyValue = "BlurCompanyValue"
    /// 淘宝错误日志上报
    case TBErrorMessage = "TbReportCollectionFailed"
    /// 点击非监管机列表按钮
    case ClickNonRegulatoryBnt = "ClickNonRegulatoryBnt"
    /// 点击监管机列表按钮
    case ClickSupervisoryBnt = "ClickSupervisoryBnt"
}
