//
//  BPMDataManager.swift
//  BPTrackerPodTesting
//
//  Created by LN-MCBK-004 on 26/12/17.
//  Copyright © 2017 LetsNurture. All rights reserved.
//

import UIKit
import CoreBluetooth

@objc public protocol BPMDataManagerDelegate : NSObjectProtocol {
    // BLE Connection methods

    
    // BLE Data callback methods
    @objc optional func connectedUserData (_ connectedUser: [String: Any])
    @objc optional func didMedCheckConnected (_ connectedPeripheral: CBPeripheral)
    @objc optional func medcheckBLEDetected (_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber)
    
    //Blood Pressure BLE Callback methods
    @objc optional func willTakeNewReading (_ BLEName: CBPeripheral)
    @objc optional func didSyncTime ()
    @objc optional func didTakeNewReading (_ readingData: [String: Any])
    @objc optional func fetchAllDataFromMedCheck (_ readingData: [Any])
    @objc optional func didClearedData ()
    @objc optional func willStartDataReading ()
    @objc optional func didEndDataReading ()
    
    
}

struct BPMCMD9Data {
    var user: String = ""
    var person1Index: String = ""
    var person2Index: String = ""
    var person3Index: String = ""
    var person1MemorySpace: String = ""
    var person2MemorySpace: String = ""
    var person3MemorySpace: String = ""
    
    public mutating func setBPMCMD9Data(uID: String, person1: String, person2: String, person3: String, person1Memory: String, person2Memory: String, person3Memory: String){
        user = uID
        person1Index = person1
        person2Index = person2
        person3Index = person3
        person1MemorySpace = person1Memory
        person2MemorySpace = person2Memory
        person3MemorySpace = person3Memory
    }
}

struct BGMCMD9Data {
    var user: String = ""
    var startingIndex: String = ""
    var endingIndex: String = ""
    var bgmType: String = ""
    
    public mutating func setBPMCMD9Data(uID: String, start: String, end: String, type: String){
        user = uID
        startingIndex = start
        endingIndex = end
        bgmType = type
    }
}

class BPMDataManager: NSObject, MCBluetoothDelegate {
    let bluetoothManager = MCBluetoothManager.getInstance()
    var delegate : BPMDataManagerDelegate?
    
    var arrBLEList = [CBPeripheral]()
    var macAddress = [String]()
    var nearbyPeripheralInfos : [CBPeripheral:Dictionary<String, AnyObject>] = [CBPeripheral:Dictionary<String, AnyObject>]()
    
    var services : [CBService]?
    var fff5Characteristic : CBCharacteristic?
    var connectedPeripheral: CBPeripheral?
    var recordCounter = 0
    var commandStr = "BT:9"
    var initialYear = 0
    var bpmDataArray :  [Any] = [Any]()
    var newReadingStart = false
    
    var BPM9CMD: BPMCMD9Data?
    var BGM9CMD: BGMCMD9Data?
    var BGMBytesString = ""
    
    /// Save the single instance
    static private var instance : BPMDataManager {
        return sharedInstance
    }
    
    private static let sharedInstance = BPMDataManager()
    /**
     Singleton pattern method
     
     - returns: Bluetooth single instance
     */
    static func getInstance() -> BPMDataManager {
        return instance
    }
    
    func didUpdateManager(){
        bluetoothManager.delegate = self
        self.perform(#selector(didUpdateState(_:)), with: nil, with: 1)
    }
    
    /**
     The bluetooth state monitor
     
     - parameter state: The bluetooth state
     */
    func didUpdateState(_ state: CBCentralManagerState) {
        print("MainController --> didUpdateState:\(state)")
        switch state {
        case .resetting:
            print("MainController --> State : Resetting")
            break
        case .poweredOn:
            bluetoothManager.startScanPeripheral()
        case .poweredOff:
            print(" MainController -->State : Powered Off")
//            noBloothAlert("MedCheck", message: "Please turn on Bluetooth to detect near by BLE devices.")
            fallthrough
        case .unauthorized:
            print("MainController --> State : Unauthorized")
//            noBloothAlert("MedCheck", message: "Please authorise bluetooth permission from application settings.")
            fallthrough
        case .unknown:
            print("MainController --> State : Unknown")
            fallthrough
        case .unsupported:
            print("MainController --> State : Unsupported")
//            noBloothAlert("MedCheck", message: "Your device is not supporting Bluetooth.")
            bluetoothManager.stopScanPeripheral()
            bluetoothManager.disconnectPeripheral()
        }
    }
    
    // MARK: BluetoothDelegate
    @objc func updateState() {
        didUpdateState(bluetoothManager.state!)
    }
    
    /**
     The callback function when central manager connected the peripheral successfully.
     
     - parameter connectedPeripheral: The peripheral which connected successfully.
     */
    func didConnectedPeripheral(_ connectedPeripheral: CBPeripheral) {
        print("MainController --> didConnectedPeripheral")
    }
    
    func getBLEMACAddress(data: NSData) -> String {
        var buffer = [UInt8](repeating: 0x00, count: data.length)
        data.getBytes(&buffer, length: buffer.count)
        let hexaValue = (data as Data).hexDescription
        return hexaValue
    }
    
    func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
        if (peripheral.name == "HL158HC BLE" || peripheral.name == "HL568HC BLE" || peripheral.name == "SFBPBLE" || peripheral.name == "SFBGBLE"){
            if let advData = advertisementData["kCBAdvDataManufacturerData"] as? NSData {
                let address = getBLEMACAddress(data: advData)
                if !macAddress.contains(address) {
                    macAddress.append(getBLEMACAddress(data: advData))
                    if !(arrBLEList.contains(peripheral)) {
                        arrBLEList.append(peripheral)
                        nearbyPeripheralInfos[peripheral] = ["RSSI": RSSI, "advertisementData": advertisementData as AnyObject]
                    } else {
                        nearbyPeripheralInfos[peripheral]!["RSSI"] = RSSI
                        nearbyPeripheralInfos[peripheral]!["advertisementData"] = advertisementData as AnyObject?
                        if connectedPeripheral != nil{
                            bluetoothManager.connectPeripheral(connectedPeripheral!)
                            bluetoothManager.stopScanPeripheral()
                        }
                    }
                }
                else{
                    if connectedPeripheral != nil{
                        bluetoothManager.connectPeripheral(connectedPeripheral!)
                        bluetoothManager.stopScanPeripheral()
                    }
                }
                if delegate != nil{
                    delegate?.medcheckBLEDetected!(peripheral, advertisementData: advertisementData, RSSI: RSSI)
                }
                
            }
        }
    }
    
    /**
     The peripheral connected method
     
     - connectPeripheral: Called when any peripherial connected
     */
    func connectPeripheral(peripheral: CBPeripheral){
        commandStr = "BT:9"
        bluetoothManager.delegate = self
        connectedPeripheral = peripheral
        bluetoothManager.connectPeripheral(connectedPeripheral!)
        print("connectedPeripheral: \(connectedPeripheral)")
        bluetoothManager.stopScanPeripheral()
    }
    
    /**
     The peripheral disconnect method
     
     - didDisconnectPeripheral: Called when peripherial is disconnected
     */
    func didDisconnectPeripheral(_ peripheral: CBPeripheral) {
        print("disconnected\(peripheral)")
        recordCounter = 0
        commandStr = "BT:9"
        arrBLEList.remove(object: peripheral)
        bluetoothManager.startScanPeripheral()
    }
    
    /**
     The peripheral services monitor
     
     - parameter services: The service instances which discovered by CoreBluetooth
     */
    func didDiscoverServices(_ peripheral: CBPeripheral) {
        services = peripheral.services
        for service in peripheral.services as [CBService]!{
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /**
     The method invoked when interrogated fail.
     
     - parameter peripheral: The peripheral which interrogation failed.
     */
    func didFailedToInterrogate(_ peripheral: CBPeripheral) {
        //        showAlert("The perapheral disconnected while being interrogated.")
        
    }
    
    /**
     The Read value for characteristics method
     
     - didDiscoverCharacteritics: when any services is discovered in connected peripheral
     */
    func didDiscoverCharacteritics(_ service: CBService) {
        for characteristic in service.characteristics!{
            
            if characteristic.uuid.uuidString == "FFF4"{ //Read Data
                if characteristic.properties == CBCharacteristicProperties.notify{
                    MCBluetoothManager.getInstance().connectedPeripheral?.setNotifyValue(true, for: characteristic)
                }
                if characteristic.properties == CBCharacteristicProperties.read{
                    MCBluetoothManager.getInstance().connectedPeripheral?.readValue(for: characteristic)
                }
                if characteristic.properties == CBCharacteristicProperties.write{
                    MCBluetoothManager.getInstance().connectedPeripheral?.setNotifyValue(true, for: characteristic)
                }
            }
            else if characteristic.uuid.uuidString == "FFF5"{
                if commandStr == "BT:9" && (MCBluetoothManager.getInstance().connectedPeripheral?.name == "HL158HC BLE" || MCBluetoothManager.getInstance().connectedPeripheral?.name == "SFBPBLE") {
                    self.fff5Characteristic = characteristic
                    timeSyncOfBPM()
                    sleep(2)
                }
                let data = commandStr.data(using: .utf8)
                MCBluetoothManager.getInstance().connectedPeripheral?.writeValue(data!, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                
            }
            else{
                if characteristic.value != nil {
                    //                    self.readOtherData(data: characteristic.value! as NSData)
                }
            }
        }
    }
    
    /**
     The Descriptors discover method
     
     - didDiscoverDescriptors: Called when any descriptor discovered from characteristics
     */
    func didDiscoverDescriptors(_ characteristic: CBCharacteristic) {
        
        self.fff5Characteristic = characteristic
    }
    
    /**
     The Read value for characteristics method
     
     - didReadValueForCharacteristic: any value is updated in characteristics
     */
    func didReadValueForCharacteristic(_ characteristic: CBCharacteristic) {
        let string = String(data: characteristic.value!, encoding: String.Encoding.utf8)
//        print("didReadValueForCharacteristic \(string)")
        if MCBluetoothManager.getInstance().connectedPeripheral?.name == "HL158HC BLE" || MCBluetoothManager.getInstance().connectedPeripheral?.name == "SFBPBLE" {
            if string == "R" {
                self.newReadingStart = true
                delegate?.willTakeNewReading!(MCBluetoothManager.getInstance().connectedPeripheral!)
            }
            if string == "f\u{05}C" {
                delegate?.didSyncTime!()
            }
            if string == "Y" {
                recordCounter = 0
                bpmDataArray.removeAll()
                delegate?.didClearedData!()
            }
            self.readBPMData(data: characteristic.value! as NSData)
        }
        else if MCBluetoothManager.getInstance().connectedPeripheral?.name == "HL568HC BLE" || MCBluetoothManager.getInstance().connectedPeripheral?.name == "SFBGBLE"{
            if string == "R" {
                self.newReadingStart = true
                delegate?.willTakeNewReading!(MCBluetoothManager.getInstance().connectedPeripheral!)
            }
            self.readBGMData(data: characteristic.value! as NSData)
        }
    }
    
    //MARK: Blood Pressure Reading functions
    func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
                Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size))
            }
        }
    }
    
    func timeSyncOfBPM() {
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        print("\(year) \(month) \(day) \(hour) \(minutes) \(seconds)")
        let yearHex = "\(year)".substring(from: 2)
        print("\(yearHex)")
        
        var buffer = [UInt8]()
        buffer.append(0xA1)
        
        buffer.append(UInt8(yearHex)!)
        buffer.append(UInt8(month))
        buffer.append(UInt8(day))
        buffer.append(UInt8(hour))
        buffer.append(UInt8(minutes))
        buffer.append(UInt8(seconds))
        let data = Data(bytes: buffer);
        
        
        
        MCBluetoothManager.getInstance().connectedPeripheral?.writeValue(data, for: self.fff5Characteristic!, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    func clearBPMDataCommand(){
        if self.fff5Characteristic != nil {
            deleteRecordsOfBPM(characteristic: self.fff5Characteristic!)
        }
    }
    
    func deleteRecordsOfBPM(characteristic: CBCharacteristic){
        var buffer = [UInt8]()
        if BPM9CMD != nil {
            buffer.append(0xA9)
            if BPM9CMD?.user == "0" {
                buffer.append(0x01)
            }
            else if BPM9CMD?.user == "10" {
                buffer.append(0x02)
            }
            else if BPM9CMD?.user == "20" {
                buffer.append(0x03)
            }
            let data = Data(bytes: buffer)
            MCBluetoothManager.getInstance().connectedPeripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    func getUserRecordIndex() -> (Int, Bool) {
        var currentIndex = 0
        var isMemoryFull = false
        if BPM9CMD?.user == "0" {
            currentIndex = Int((BPM9CMD?.person1Index)!)!
            isMemoryFull = BPM9CMD?.person1MemorySpace == "1" ? true : false
        }
        else if BPM9CMD?.user == "10" {
            currentIndex = Int((BPM9CMD?.person2Index)!)!
            isMemoryFull = BPM9CMD?.person2MemorySpace == "1" ? true : false
        }
        else if BPM9CMD?.user == "20" {
            currentIndex = Int((BPM9CMD?.person3Index)!)!
            isMemoryFull = BPM9CMD?.person3MemorySpace == "1" ? true : false
        }
        return (currentIndex, isMemoryFull)
    }
    
    func readBPMData(data: NSData) {
        if data.length < 8{
//            SVProgressHUD.dismiss()
            return
        }
        var buffer = [UInt8](repeating: 0x00, count: data.length)
        data.getBytes(&buffer, length: buffer.count)
        
        let hexaValue = (data as Data).hexDescription
        
        if hexaValue == "fa5af1f2fa5af3f4" {
            print("Starting data")
            bpmDataArray.removeAll()
            recordCounter = 0
            delegate?.willStartDataReading!()
//            dismissPopUp()
//            lastBPMResultCount = appDelegate.bpmDataArray.count
//            SVProgressHUD.show(withStatus: "Fetching...")
            return
        }
        
        if hexaValue == "f5a5f5f6f5a5f7f8" {
//            SVProgressHUD.dismiss()
            if commandStr == "BT:9" {
                if BPM9CMD != nil {
                    var userNumber = "1"
                    if BPM9CMD?.user == "0" {
                        commandStr = "BT:0"
                        userNumber = "1"
                    }
                    else if BPM9CMD?.user == "10" {
                        commandStr = "BT:1"
                        userNumber = "2"
                    }
                    else if BPM9CMD?.user == "20" {
                        commandStr = "BT:2"
                        userNumber = "3"
                    }
                    print(commandStr)
                    let userIndexes = getUserRecordIndex()
                    
                    let userData = ["user": userNumber, "recordIndex": "\(userIndexes.0)", "isMemoryfull" : "\(userIndexes.1)"]
                    delegate?.connectedUserData!(userData)
                }
                else{
                    commandStr = "BT:0"
                }
                for service in services!{
                    MCBluetoothManager.getInstance().connectedPeripheral?.discoverCharacteristics(nil, for: service)
                }
            }
            else{
                delegate?.didEndDataReading!()
                delegate?.fetchAllDataFromMedCheck!(bpmDataArray)
                if BPM9CMD != nil && !bpmDataArray.isEmpty{
                    var currentIndex = getUserRecordIndex().0
                    if currentIndex > bpmDataArray.count {
                        currentIndex = bpmDataArray.count
                    }
                    print(currentIndex)
                    let obj = bpmDataArray[currentIndex-1]
                    
                    if connectedPeripheral != nil {
                        if self.newReadingStart {
                            delegate?.didTakeNewReading!(obj as! [String : Any])
                            self.newReadingStart = false
                        }
                    }
                }
            }
//            SVProgressHUD.dismiss()
            return
        }
        let binaryData = hexaValue.hexaToBinaryString.pad(with: "0", toLength: 64)
        if commandStr == "BT:9"{
            self.initialYear = Int(buffer[1])
            let user = String(buffer[0], radix: 16)
            print(user)
            
            
            var lastUser = user
            var lastReadingCount = bpmDataArray.count
            if BPM9CMD != nil {
                lastUser = (BPM9CMD?.user)!
                lastReadingCount = getUserRecordIndex().0
                print("last saved user: \(lastUser) count: \(lastReadingCount)")
                
            }
            
            let memory = String(buffer[6], radix: 16)
            print("memory \(memory)")
            let BYTE06 = memory.decimalToHexaString.hexaToBinaryString.pad(with: "0", toLength: 8)
            print("BYTE06 \(BYTE06)")
            let person1MemorySpace = BYTE06.substring(with: 7..<8).binaryToDecimal
            let person2MemorySpace = BYTE06.substring(with: 6..<7).binaryToDecimal
            let person3MemorySpace = BYTE06.substring(with: 5..<6).binaryToDecimal
            
            let data = BPMCMD9Data.init(user: user, person1Index: "\(buffer[7])", person2Index: "\(buffer[4])", person3Index: "\(buffer[5])", person1MemorySpace: "\(person1MemorySpace)", person2MemorySpace: "\(person2MemorySpace)", person3MemorySpace: "\(person3MemorySpace)")
            
            BPM9CMD = data
            if lastUser != BPM9CMD?.user{
                //showAlert("Device user changed")
                var currentIndex = 0
                if BPM9CMD?.user == "0" {
                    currentIndex = Int((BPM9CMD?.person1Index)!)!
                }
                else if BPM9CMD?.user == "10" {
                    currentIndex = Int((BPM9CMD?.person2Index)!)!
                }
                else if BPM9CMD?.user == "20" {
                    currentIndex = Int((BPM9CMD?.person3Index)!)!
                }
//                if newReadingStart {
//                    lastBPMResultCount = currentIndex != 0 ? currentIndex - 1 : 0
//                }
//                else{
//                    lastBPMResultCount = currentIndex
//                }
            }
            else{
                //showAlert("Device user same")
            }
        }
        else{
            print(binaryData)
            if binaryData.characters.count == 64 && recordCounter < getUserRecordIndex().0{
                let BYTE00 = binaryData.substring(with: 0..<8)
                let BYTE0_BIT1 = BYTE00.substring(with: 4..<8).binaryToDecimal // month
                let BYTE0_BIT2 = BYTE00.substring(with: 0..<4).binaryToHexaString //year
                
                let year = BYTE0_BIT2.hexaToDecimal + 2000 + self.initialYear
                
                
                let BYTE01 = binaryData.substring(with: 8..<16).binaryToDecimal //Day
                
                let BYTE02 = binaryData.substring(with: 16..<24)
                let BYTE03 = binaryData.substring(with: 24..<32)
                let BYTE04 = binaryData.substring(with: 32..<40)
                let BYTE05 = binaryData.substring(with: 40..<48)
                let BYTE06 = binaryData.substring(with: 48..<56)
                let BYTE2_BIT1 = BYTE02.substring(with: 4..<8).binaryToDecimal// hour
                let BYTE2_BIT2 = BYTE02.substring(with: 3..<4) //IBH
                let BYTE2_BIT3 = BYTE02.substring(with: 0..<1) //0AM/1PM
                
                let minute: Int = BYTE03.binaryToDecimal //hour
                let timeStr = String(format:"%02d:%02d %@", BYTE2_BIT1, minute, (Int(BYTE2_BIT3) == 1 ? "PM" : "AM"))
                let sysPrefix = (BYTE04.substring(with: 0..<4).binaryToDecimal*100)
                let diaPrefix = (BYTE04.substring(with: 4..<8).binaryToDecimal*100)
                
//                print("syPrefix:\(sysPrefix) diaPrefix:\(diaPrefix)")
                
                var sysData = BYTE05.binToHex().ns.integerValue
                var diaData = BYTE06.binToHex().ns.integerValue
                
                sysData =  sysPrefix+sysData
                diaData =  diaPrefix+diaData
                
//                print("sysData==> \(sysData)   diaData==>\(diaData)")
                if sysData > 0{
                    let dataStr = String(format:"%02d-%02d-%04d %@",BYTE01,BYTE0_BIT1,year,timeStr)
//                    let date1 = dataStr.getLocalTimeZoneDate()
                    
//                    print(String(format:"%02d-%02d-%04d %@",BYTE01,BYTE0_BIT1,year,timeStr))
                    
                    let data = ["device":"Blood Pressure", "data" : ["Systolic":  String(format: "%d",sysData), "Diastolic" : String(format: "%d",diaData), "Date" : dataStr, "Indicator" : BYTE2_BIT2, "Pulse" : "\(buffer[7])"]]  as [String : Any]
                    
                    self.bpmDataArray.append(data)
                    recordCounter += 1
                    
                }
            }
        }
    }
    
    //MARK: Glucose machine Reading functions
    func readBGMData(data: NSData) {
        
        if data.length < 8{
            return
        }
        var buffer = [UInt8](repeating: 0x00, count: data.length)
        data.getBytes(&buffer, length: buffer.count)
        print("array \(buffer)")
        
        let hexaValue = (data as Data).hexDescription
        print("hexaValue: \(hexaValue)")
        
        if hexaValue == "fa5af1f2fa5af3f4" {
            print("Starting data")
            
            bpmDataArray.removeAll()
            recordCounter = 0
            delegate?.willStartDataReading!()
            
            BGMBytesString = ""
            
            return
        }
        
        if hexaValue == "f5a5f5f6f5a5f7f8" {
            print("Ending data")
            delegate?.didEndDataReading!()
            if commandStr == "BT:9" {
                commandStr = "BT:0"
                for service in services!{
                    MCBluetoothManager.getInstance().connectedPeripheral?.discoverCharacteristics(nil, for: service)
                }
            }
            else if commandStr == "BT:0" {
                BGMBT0CommandRead()
            }
            return
        }
        if hexaValue == "ffffffffffffffff" {
            return
        }
        if commandStr == "BT:0" {
            BGMBytesString.append(hexaValue)
        }
        else{
            self.initialYear = Int(buffer[1])
            let user = String(buffer[0], radix: 16)
            let start = String(buffer[2], radix: 16)
            let end = String(buffer[3], radix: 16)
            let typeBinary = String(buffer[7], radix: 16).hexaToBinaryString
            let type = typeBinary.substring(with: 7..<8)
            
            print(user)
            let data = BGMCMD9Data.init(user: user, startingIndex: start, endingIndex: end, bgmType: type)
            BGM9CMD = data
            recordCounter = 0
            BGMBT9CommandRead()
           
            let userData = ["user": "01", "startingRecordIndex": "\(start)", "endingRecordIndex" : "\(end)", "bgmType":"\(type)"]
            delegate?.connectedUserData!(userData)
        }
        
    }
    
    func BGMBT0CommandRead() {
        
        print("BGMBytesString==> \(BGMBytesString)")
        BGMBytesString.insert(separator: "@#", every: 12)
        print("BGMBytesString==> \(BGMBytesString)")
        
        let byteArray = BGMBytesString.components(separatedBy: "@#")
        print(byteArray)
        
        for (index, binaryStr) in byteArray.enumerated(){
            //        for binaryStr in byteArray {
            print("binaryStr ==> \(binaryStr)")
            if index < Int((BGM9CMD?.endingIndex)!)! {
                let BYTE00 = binaryStr.substring(with: 0..<2) .hexaToBinaryString.pad(with: "0", toLength: 8)
                let BYTE0_BIT1 = BYTE00.substring(with: 1..<8).binaryToDecimal //year
                let BYTE0_BIT2 = BYTE00.substring(with: 0..<1) //0AM/1PM
                
                let BYTE01 = binaryStr.substring(with: 2..<4) .hexaToBinaryString.pad(with: "0", toLength: 8)
                let BYTE1_BIT1 = BYTE01.substring(with: 0..<4).binaryToDecimal // month
                let BYTE1_BIT2 = BYTE01.substring(with: 4..<8).binaryToDecimal //hour
                
                
                let BYTE02 = binaryStr.substring(with: 4..<6).hexaToDecimal
                print("day: \(BYTE02)-\(BYTE1_BIT1)-\(BYTE0_BIT1)")
                let dateStr = String(format:"%02d-%02d-%d", BYTE02, BYTE1_BIT1, Int(BYTE0_BIT1 + 2000))
                
                let BYTE03 = binaryStr.substring(with: 6..<8) .hexaToBinaryString.pad(with: "0", toLength: 8)
                let BYTE03_BIT1 = BYTE03.substring(with: 0..<2) // AC/PC indicator
                let BYTE03_BIT2 = BYTE03.substring(with: 2..<8).binaryToDecimal // minutes
                let timeStr = String(format:"%02d:%02d %@", BYTE1_BIT2, BYTE03_BIT2, (Int(BYTE0_BIT2) == 1 ? "PM" : "AM"))
                print("timeStr \(timeStr)")
                print("Ac/PC indicator: \(BYTE03_BIT1)")
                
                let BYTE04 = binaryStr.substring(with: 8..<10) .hexaToDecimal
                print("LOW BYTE04: \(BYTE04)")
                
                let BYTE05 = binaryStr.substring(with: 10..<12) .hexaToDecimal
                print("HIGH BYTE05: \(BYTE05)")
                
//                let dataStr = String(format:"%@ %@",dateStr,timeStr)
//                let date1 = dataStr.getLocalTimeZoneDate()
                
                let data = ["device":"Glucose", "data" : ["high_blood":  String(format: "%d",BYTE05), "Date" : dateStr+" "+timeStr, "Indicator" : BYTE03_BIT1]]  as [String : Any]
                
                self.bpmDataArray.append(data)
                recordCounter += 1
                if index+1 == Int((BGM9CMD?.endingIndex)!)! {
                    delegate?.fetchAllDataFromMedCheck!(bpmDataArray)
                }
            }
        }
    }
    
    func BGMBT9CommandRead(){
        print("BGM9CMD \(BGM9CMD)")
    }
    func readOtherData(data: NSData) {
        var buffer = [UInt8](repeating: 0x00, count: data.length)
        data.getBytes(&buffer, length: buffer.count)
        print("readOtherData array \(buffer)")
        let str = buffer.reduce("", { $0 + String(format: "%c", $1)})
        print("readOtherData str ==> \(str)")
    }
}
