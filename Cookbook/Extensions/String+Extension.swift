//
//  String.swift
//  Cookbook
//
//  Created by David Klopp on 01.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

let urlRegex = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"

extension String {

    /**
     True if a string matches a regex, false otherwise.
     */
    static func ~= (lhs: String, rhs: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return nil }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range)
    }

    /**
     Return nil if no match is found, otherwise return the URL range inside the string.
     */
    func containedURL() -> NSRange? {
        let textCheckingResult = self ~= urlRegex
        if let result = textCheckingResult {
            return result.range
        }
        return nil
    }

    /**
    Convert a P[n]Y[n]M[n]DT[n]H[n]M[n]S or P[n]W string to a readable format with d:h:m:s. If the string is has an
    invalid format, an empty string is returned.
     - Return: readable time string or empty string
    */
    func readableTime() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        if let comps = try? DateComponents.from(iso8601String: self), let str = formatter.string(from: comps) {
            return str
        }
        return ""
    }

    var intValue: Int? {
        return Int(self)
    }

    var doubleValue: Double? {
        return Double(self)
    }
}
