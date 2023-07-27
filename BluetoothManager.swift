//
//  BluetoothManager.swift
//  BlueDemo
//
//  Created by Q Z on 2023/6/16.
//

import UIKit
import CoreBluetooth

class BluetoothManager: NSObject {
    deinit{
        log.info("---------------------")
    }
    
    private var centralManager: CBCentralManager!
    private var identifierList = [[String: Any]]()
    public func scanBle() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public var isScanning: Bool {
        return self.centralManager.isScanning
    }
    
    public func stopScan() {
        if isScanning == true {
            self.centralManager.stopScan()
        }
    }
    
    public func scanForPeripheral() {
        if isScanning == false {
            self.centralManager.scanForPeripherals(withServices: nil)
            TrackManager.default.track(.StartBluetoothDevicesDiscovery)
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        //确保本中心设备支持蓝牙低能耗（BLE）并开启时才能继续操作
        switch central.state{
        case .unknown:
            log.info("未知")
        case .resetting:
            log.info("蓝牙重置中")
        case .unsupported:
            log.info("本机不支持BLE")
        case .unauthorized:
            log.info("未授权")
        case .poweredOff:
            log.info("蓝牙未开启")
        case .poweredOn:
            log.info("蓝牙开启")
            //MARK: 扫描正在广播的外设--每当发现外设时都会调用didDiscover peripheral方法
            scanForPeripheral()
        @unknown default:
            log.info("来自未来的错误")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let data = ["deviceId": peripheral.identifier.uuidString,
                   "connectable": peripheral.state.rawValue,
                   "name": peripheral.name ?? "未知设备",
                   "RSSI": RSSI] as [String : Any]
        if self.identifierList.contains(where: { oldData in
            return oldData["deviceId"] as? String == data["deviceId"] as? String
        }) == false{
            self.identifierList.append(data)
//            log.info(self.identifierList)
            TrackManager.default.track(.StartBluetoothDevicesDiscovery, property: data)
        }
    }
}
