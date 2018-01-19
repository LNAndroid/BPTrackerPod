//
//  BLE+Extension.swift
//  BPTrackerPodTesting
//
//  Created by LN-MCBK-004 on 26/12/17.
//  Copyright © 2017 LetsNurture. All rights reserved.
//

import UIKit

extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}

extension String {
    var drop0xPrefix:          String { return hasPrefix("0x") ? String(characters.dropFirst(2)) : self }
    var drop0bPrefix:          String { return hasPrefix("0b") ? String(characters.dropFirst(2)) : self }
    var hexaToDecimal:            Int { return Int(drop0xPrefix, radix: 16) ?? 0 }
    var hexaToBinaryString:    String { return String(hexaToDecimal, radix: 2) }
    var decimalToHexaString:   String { return String(Int(self) ?? 0, radix: 16) }
    var decimalToBinaryString: String { return String(Int(self) ?? 0, radix: 2) }
    var binaryToDecimal:          Int { return Int(drop0bPrefix, radix: 2) ?? 0 }
    var binaryToHexaString:    String { return String(binaryToDecimal, radix: 16) }
    func pad(with character: String, toLength length: Int) -> String {
        let padCount = length - self.characters.count
        guard padCount > 0 else { return self }
        
        return String(repeating: character, count: padCount) + self
    }
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return substring(from: fromIndex)
    }
    public var ns: NSString {
        return self as NSString
    }
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return substring(to: toIndex)
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return substring(with: startIndex..<endIndex)
    }
    func binToHex() -> String {
        // binary to integer:
        let num = self.withCString { strtoul($0, nil, 2) }
        // integer to hex:
        let hex = String(num, radix: 16, uppercase: true) // (or false)
        return hex
    }
    //Insert a character at N index
    var pairs: [String] {
        var result: [String] = []
        let characters = Array(self.characters)
        stride(from: 0, to: characters.count, by: 2).forEach {
            result.append(String(characters[$0..<min($0+2, characters.count)]))
        }
        return result
    }
    mutating func insert(separator: String, every n: Int) {
        self = inserting(separator: separator, every: n)
    }
    func inserting(separator: String, every n: Int) -> String {
        var result: String = ""
        let characters = Array(self.characters)
        stride(from: 0, to: characters.count, by: n).forEach {
            result += String(characters[$0..<min($0+n, characters.count)])
            if $0+n < characters.count {
                result += separator
            }
        }
        return result
    }
    
    func getLocalTimeZoneDate(dateFormat:String="dd-MM-yyyy hh:mm a") -> Date{
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale.current
        let dateGMT = dateFormatter.date(from: self)!
        let timeZoneOffset = NSTimeZone.system.secondsFromGMT(for: dateGMT)
        let localDate = dateGMT.addingTimeInterval(TimeInterval(timeZoneOffset))
        return localDate
    }
}
extension Array where Element: Equatable {
    @discardableResult mutating func remove(object: Element) -> Bool {
        if let index = index(of: object) {
            self.remove(at: index)
            return true
        }
        return false
    }
    
    @discardableResult mutating func remove(where predicate: (Array.Iterator.Element) -> Bool) -> Bool {
        if let index = self.index(where: { (element) -> Bool in
            return predicate(element)
        }) {
            self.remove(at: index)
            return true
        }
        return false
    }
    
}

extension DateFormatter
{
    func setLocal() {
        self.locale = Locale.init(identifier: "en_US_POSIX")
        self.timeZone = TimeZone(abbreviation: "UTC")!
    }
}

extension Date {
    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }
}

