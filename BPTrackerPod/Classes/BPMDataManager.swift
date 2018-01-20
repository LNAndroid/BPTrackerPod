//
//  BPMDataManager.swift
//  BPTrackerPodTesting
//
//  Created by LN-MCBK-004 on 26/12/17.
//  Copyright © 2017 LetsNurture. All rights reserved.
//

import UIKit
import CoreBluetooth

/// This class will return data from BLE. This class has almost all type of callbacks methods which will we usefull to you.

@objc public protocol BPMDataManagerDelegate : NSObjectProtocol {
    
    
    /**
     This will return User data from BLE. i.e User1, User2 or User3. It has all kind of information about User.
     
     @return JSON data which containts userNumber, start & end index, full or empty indicator.
     */
    @objc optional func connectedUserData (_ connectedUser: [String: Any])
    
    /**
     This will callback when any MedCheck device will connect.
     
     @return Will return connectedPeripheral
     */
    @objc optional func didMedCheckConnected (_ connectedPeripheral: CBPeripheral)
    
    /**
     This will callback when any MedCheck device will detected while scanning.
     
     @return Will return peripheral, advertisementData & RSSI.
     */
    @objc optional func medcheckBLEDetected (_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber)
    
    
    //Blood Pressure BLE Callback methods
    /**
     This will callback when any MedCheck device start to take new reading when it is connected with mobile.
     
     @return Will return peripheral.
     */
    @objc optional func willTakeNewReading (_ BLEName: CBPeripheral)
    
    /**
     This will callback when MedCheck device time is synchronized with current time.
     */
    @objc optional func didSyncTime ()
    
    /**
     This will callback when any MedCheck device takes new reading when it is connected. This will only work for Blood Pressure machine.
     
     @return Will return single JSON object.
     */
    @objc optional func didTakeNewReading (_ readingData: [String: Any])
    
    /**
     This will callback when any MedCheck device is connected and fetched all records from MedCheck Device.
     
     @return Will return Array of JSON object.
     */
    @objc optional func fetchAllDataFromMedCheck (_ readingData: [Any])
    
    /**
     This will callback when any MedCheck device is connected and call clear command. This will only work for Blood Pressure machine.
     */
    @objc optional func didClearedData ()
    
    /**
     This will callback when any MedCheck device is connected and try to fetch any data from BLE.
     */
    @objc optional func willStartDataReading ()
    
    /**
     This will callback when any MedCheck device is connected and fetched all data from BLE.
     */
    @objc optional func didEndDataReading ()
    
    
}

/// This struct will store Blood Pressure machine user data. It will contain UserNumber, User1 record index, User2 record index, User3 record index, User1 memory space, User2 memory space, User3 memory space. If memory space is 1 that means all record of that user are full. As machine can store 40 records for each user, we need to add 40 + User record index.

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

/// This struct will store Glucode machine user data. It will contain UserNumber, startingIndex & endingIndex. bgmType will indicate either user has selected mmoL or mg/dL.

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

/// This class is core class of this entier Pod. Use this class to get Blood Pressure & Glucose reading on BLE. This class will also handle BluetoothManager instance. So no need to create seperate instance for same.

public class BPMDataManager: NSObject, MCBluetoothDelegate {
    /// This will have CoreBluetoothManager all methods.
    public let bluetoothManager = MCBluetoothManager.getInstance()
    
    /// This will assign BPMDataManagerDelegate.
    public var delegate : BPMDataManagerDelegate?
    
    /// This will containts all scanned BLE devices in array in form of CBPeripheral.
    public var arrBLEList = [CBPeripheral]()
    
    /// This will containts all scanned BLE devices's MAC Address in array in form of String.
    public var macAddress = [String]()
    
    /// This will containts all scanned BLE devices's information i.e CBPeripheral in form of Dictionary.
    public var nearbyPeripheralInfos : [CBPeripheral:Dictionary<String, AnyObject>] = [CBPeripheral:Dictionary<String, AnyObject>]()
    
    /// This will containts all services of connected peripherals.
    public var services : [CBService]?
    
    /// This will containts all characteristics of connected service of connected peripherals.
    public var fff5Characteristic : CBCharacteristic?
    
    /// This will containts instance of connected peripheral.
    public var connectedPeripheral: CBPeripheral?
    
    /// This will count fetched records from BLE.
    var recordCounter = 0
    
    /// This will have command value which we need to pass to BLE.
    var commandStr = "BT:9"
    
    /// This will set initial year from fetched record.
    var initialYear = 0
    
    /// This will contain all records of BLE machine.
    var bpmDataArray :  [Any] = [Any]()
    
    /// This will be true once device is connected and start to take new reading.
    var newReadingStart = false
    
    /// These are objects of BT:9 command response from BLE.
    var BPM9CMD: BPMCMD9Data?
    var BGM9CMD: BGMCMD9Data?
    
    /// This will contain Glucose machine byte string.
    var BGMBytesString = ""
    
    /// Save the single instance
    //    open static var instance : BPMDataManager {
    //        return sharedInstance
    //    }
    //
    //    public let sharedInstance = BPMDataManager()
    //    /**
    //     Singleton pattern method
    //
    //     - returns: Bluetooth single instance
    //     */
    //    open static func getInstance() -> BPMDataManager {
    //        return instance
    //    }
    
    /// sharedInstance of BPMDataManager class.
    public static let sharedInstance = BPMDataManager()
    
    /**
     This will check whether Bluetooth is On/Off in device. If ON then call scan function from MCBluetoothManager class.
     */
    open func didUpdateManager(){
        bluetoothManager.delegate = self
        self.perform(#selector(didUpdateState(_:)), with: nil, with: 1)
    }
    
    /**
     The bluetooth state monitor
     
     - parameter state: The bluetooth state
     */
    @objc public func didUpdateState(_ state: CBCentralManagerState) {
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
    /**
     This will check whether Bluetooth is On/Off in device. If ON then call scan function from MCBluetoothManager class.
     */
    @objc func updateState() {
        didUpdateState(bluetoothManager.state!)
    }
    
    /**
     The callback function when central manager connected the peripheral successfully.
     
     - parameter connectedPeripheral: The peripheral which connected successfully.
     */
    public func didConnectedPeripheral(_ connectedPeripheral: CBPeripheral) {
        print("MainController --> didConnectedPeripheral")
    }
    
    /**
     This will calculate MAC Address from scanned device.
     @param Data from advertisementData["kCBAdvDataManufacturerData"]
     @return MAC address string
     */
    func getBLEMACAddress(data: NSData) -> String {
        var buffer = [UInt8](repeating: 0x00, count: data.length)
        data.getBytes(&buffer, length: buffer.count)
        let hexaValue = (data as Data).hexDescription
        return hexaValue
    }
    
    /**
     This will returned all BLEs near by. We are just returning those BLEs which are MedCheck devices.
     @return peripheral, advertisementData & RSSI
     */
    public func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
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
    public func connectPeripheral(peripheral: CBPeripheral){
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
    public func didDisconnectPeripheral(_ peripheral: CBPeripheral) {
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
    public func didDiscoverServices(_ peripheral: CBPeripheral) {
        services = peripheral.services
        for service in peripheral.services as [CBService]!{
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /**
     The method invoked when interrogated fail.
     
     - parameter peripheral: The peripheral which interrogation failed.
     */
    public func didFailedToInterrogate(_ peripheral: CBPeripheral) {
        //        showAlert("The perapheral disconnected while being interrogated.")
        
    }
    
    /**
     The Read value for characteristics method
     
     - didDiscoverCharacteritics: when any services is discovered in connected peripheral
     */
    public func didDiscoverCharacteritics(_ service: CBService) {
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
    public func didDiscoverDescriptors(_ characteristic: CBCharacteristic) {
        
        self.fff5Characteristic = characteristic
    }
    
    /**
     The Read value for characteristics method
     
     - didReadValueForCharacteristic: any value is updated in characteristics
     */
    public func didReadValueForCharacteristic(_ characteristic: CBCharacteristic) {
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
    /**
     This will synch Blood Pressure machine time whenever machine is connected with device. Once BLE's time is synchronized successfully its callback returned.
     */
    public func timeSyncOfBPM() {
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
    
    /**
     This will clear all data of a selected user from Blood Pressure machine.
     */
    public func clearBPMDataCommand(){
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
    
    /**
     This will returned current user record index with full or empty status.
     */
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
    
    /**
     This will calculate on BLE byte data and get all records from Blood Pressure device.
     */
    func readBPMData(data: NSData) {
        if data.length < 8{
            //            SVProgressHUD.dismiss()
            return
        }
        var buffer = [UInt8](repeating: 0x00, count: data.length)
        data.getBytes(&buffer, length: buffer.count)
        
        let hexaValue = (data as Data).hexDescription
        
        if hexaValue == "fa5af1f2fa5af3f4" { // Starting node of each command
            print("Starting data")
            bpmDataArray.removeAll()
            recordCounter = 0
            delegate?.willStartDataReading!()
            return
        }
        
        if hexaValue == "f5a5f5f6f5a5f7f8" { // ending node of each command
            if commandStr == "BT:9" { //Will store BT:9 command data in struct.
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
                        if self.newReadingStart {//If user has taken new reading.
                            delegate?.didTakeNewReading!(obj as! [String : Any])
                            self.newReadingStart = false
                        }
                    }
                }
            }
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
            }
            
            let memory = String(buffer[6], radix: 16)
            let BYTE06 = memory.decimalToHexaString.hexaToBinaryString.pad(with: "0", toLength: 8)
            let person1MemorySpace = BYTE06.substring(with: 7..<8).binaryToDecimal
            let person2MemorySpace = BYTE06.substring(with: 6..<7).binaryToDecimal
            let person3MemorySpace = BYTE06.substring(with: 5..<6).binaryToDecimal
            
            //Store all data to struct
            let data = BPMCMD9Data.init(user: user, person1Index: "\(buffer[7])", person2Index: "\(buffer[4])", person3Index: "\(buffer[5])", person1MemorySpace: "\(person1MemorySpace)", person2MemorySpace: "\(person2MemorySpace)", person3MemorySpace: "\(person3MemorySpace)")
            
            BPM9CMD = data
            if lastUser != BPM9CMD?.user{ // If device user is changed
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
            }
        }
        else{
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
                
                var sysData = BYTE05.binToHex().ns.integerValue
                var diaData = BYTE06.binToHex().ns.integerValue
                
                sysData =  sysPrefix+sysData
                diaData =  diaPrefix+diaData
                if sysData > 0{
                    let dataStr = String(format:"%02d-%02d-%04d %@",BYTE01,BYTE0_BIT1,year,timeStr)
                    let data = ["device":"Blood Pressure", "data" : ["Systolic":  String(format: "%d",sysData), "Diastolic" : String(format: "%d",diaData), "Date" : dataStr, "Indicator" : BYTE2_BIT2, "Pulse" : "\(buffer[7])"]]  as [String : Any]
                    
                    self.bpmDataArray.append(data)
                    recordCounter += 1
                    
                }
            }
        }
    }
    
    
    //MARK: Glucose machine Reading functions
    /**
     This will calculate on BLE byte data and get all records from Glucose device.
     */
    func readBGMData(data: NSData) {
        
        if data.length < 8{
            return
        }
        var buffer = [UInt8](repeating: 0x00, count: data.length)
        data.getBytes(&buffer, length: buffer.count)
        
        let hexaValue = (data as Data).hexDescription
        
        if hexaValue == "fa5af1f2fa5af3f4" { //start node of all command
            print("Starting data")
            bpmDataArray.removeAll()
            recordCounter = 0
            delegate?.willStartDataReading!()
            BGMBytesString = ""
            return
        }
        if hexaValue == "f5a5f5f6f5a5f7f8" {//ending node of all command
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
        if hexaValue == "ffffffffffffffff" { //Empty data
            return
        }
        if commandStr == "BT:0" { //Glucose machine will have only one user.
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
    
    /**
     This will calculate on BLE byte data string and get all records from Glucose device.
     */
    func BGMBT0CommandRead() {
        BGMBytesString.insert(separator: "@#", every: 12)
        let byteArray = BGMBytesString.components(separatedBy: "@#")
        for (index, binaryStr) in byteArray.enumerated(){
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
                
                let BYTE04 = binaryStr.substring(with: 8..<10) .hexaToDecimal
                
                let BYTE05 = binaryStr.substring(with: 10..<12) .hexaToDecimal
                
                let data = ["device":"Glucose", "data" : ["high_blood":  String(format: "%d",BYTE05), "Date" : dateStr+" "+timeStr, "Indicator" : BYTE03_BIT1]]  as [String : Any]
                
                self.bpmDataArray.append(data)
                recordCounter += 1
                if index+1 == Int((BGM9CMD?.endingIndex)!)! {
                    delegate?.fetchAllDataFromMedCheck!(bpmDataArray)
                }
            }
        }
    }
    
    /**
     This will prind BGM9CMD data.
     */
    func BGMBT9CommandRead(){
        print("BGM9CMD \(BGM9CMD)")
    }
    
    /**
     This will some other data from Glucose machine.
     */
    func readOtherData(data: NSData) {
        var buffer = [UInt8](repeating: 0x00, count: data.length)
        data.getBytes(&buffer, length: buffer.count)
        let str = buffer.reduce("", { $0 + String(format: "%c", $1)})
        print("readOtherData str ==> \(str)")
    }
}

