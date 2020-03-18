//
//  String.swift
//  Cookbook
//
//  Created by David Klopp on 01.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension String {
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

    /**
     Convert a readable time string to iso8601String format.
     - Return: iso8601String or empty string
     */
    func iso8601() -> String {
        let formatter = DateFormatter()
        var format = ""
        for comp in ["ss", "mm", "HH", "dd"] {
            format = comp+(format.isEmpty ? "" : ":"+format)
            formatter.dateFormat = format
            if let date = formatter.date(from: self) {
                let refDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
                let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second],
                                                                     from: refDate, to: date)
                return dateComponents.iso8601String()
            }
        }
        return ""
    }

    /// Convert the string to an Int.
    var intValue: Int? {
        return Int(self)
    }

    /// Convert the string to an Double.
    var doubleValue: Double? {
        return Double(self)
    }
}
