# BPTrackerPod

[![CI Status](http://img.shields.io/travis/LNAndroid/BPTrackerPod.svg?style=flat)](https://travis-ci.org/LNAndroid/BPTrackerPod)
[![Version](https://img.shields.io/cocoapods/v/BPTrackerPod.svg?style=flat)](http://cocoapods.org/pods/BPTrackerPod)
[![License](https://img.shields.io/cocoapods/l/BPTrackerPod.svg?style=flat)](http://cocoapods.org/pods/BPTrackerPod)
[![Platform](https://img.shields.io/cocoapods/p/BPTrackerPod.svg?style=flat)](http://cocoapods.org/pods/BPTrackerPod)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

BPTrackerPod is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BPTrackerPod'
```
### Source files
Alternatively you can directly add the `BPTrackerPod` folder to your project.
1. Download the latest code version or add the repository as a git submodule to your git-tracked project.
2. Open your project in Xcode, then drag and drop `BPTrackerPod` folder onto your project (use the "Product Navigator view"). Make sure to select Copy items when asked if you extracted the code archive outside of your project.

## Usage

### Pod Import
<pre>
import BPTrackerPod
</pre>

### Get Shared Instance of BPMDataManager

<pre>
let bluetoothManager = BPMDataManager.sharedInstance
</pre>

### Set delegate from ViewDidLoad()
<pre>
override func viewDidLoad() {
    super.viewDidLoad()
    .
    .
    bluetoothManager.delegate = self
    bluetoothManager.didUpdateManager()
}
</pre>

### Get BPMDataManager delegate method for scanned MedCheck devices

<pre>
extension ViewController: BPMDataManagerDelegate{
    func medcheckBLEDetected(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
        print(bluetoothManager.arrBLEList)
    }
}
</pre>

### Connect to MedCheck BLE device

<pre>
    BPMDataManager.sharedInstance.connectPeripheral(peripheral: connectedPeripheral!)
</pre>

### Disconnect to MedCheck BLE device

<pre>
    BPMDataManager.sharedInstance.didDisconnectPeripheral(connectedPeripheral!)
</pre>

### Clear Blood Pressure data from MedCheck BLE device

<pre>
    BPMDataManager.sharedInstance.clearBPMDataCommand()
</pre>

### Synch current time with Blood Pressure data from MedCheck BLE device

<pre>
    BPMDataManager.sharedInstance.timeSyncOfBPM()
</pre>

### Synch current time with Blood Pressure data from MedCheck BLE device

<pre>
    BPMDataManager.sharedInstance.timeSyncOfBPM()
</pre>

### BPMDataManagerDelegate methods combined with CoreBluetoothManagerDelegate methods.

<pre>
extension ViewController: BPMDataManagerDelegate{
    func medcheckBLEDetected(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
        if bpmDataManager.bluetoothManager.connected {
        bpmDataManager.connectPeripheral(peripheral: bpmDataManager.connectedPeripheral!)
        }
    }

    func didMedCheckConnected(_ connectedPeripheral: CBPeripheral) {
        print("didMedCheckConnected \(connectedPeripheral)")
    }

    func connectedUserData(_ connectedUser: [String : Any]) {
        print("connectedUserData \(connectedUser)")
    }
    func willTakeNewReading(_ BLEName: CBPeripheral) {
        print("willStartDataReading \(BLEName)")
    }

    func didSyncTime() {
        print("didSyncTime")
    }

    func didTakeNewReading(_ readingData: [String : Any]) {
        print("didTakeNewReading \(jsonStringConvert(readingData))")
    }

    func showAlertMessage(_ title : String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func fetchAllDataFromMedCheck(_ readingData: [Any]) {
        print("fetchAllDataFromMedCheck \(jsonStringConvert(readingData))")
    }

    func didClearedData() {
        print("didClearedData")
    }

    func willStartDataReading() {
        print("willStartDataReading")
    }

    func didEndDataReading() {
        print("didEndDataReading")
    }

    func jsonStringConvert(_ obj : Any) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: obj, options: JSONSerialization.WritingOptions.prettyPrinted)
            return  String(data: jsonData, encoding: String.Encoding.utf8)! as String

        } catch {
            return ""
        }
    }
}
</pre>

## Author

LNAndroid, pratik.patel@letsnurture.com

## License

BPTrackerPod is available under the MIT license. See the LICENSE file for more info.
