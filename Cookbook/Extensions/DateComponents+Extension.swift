/**
 Reference: http://en.wikipedia.org/wiki/ISO_8601#Durations
 */

import Foundation

struct InvalidFormatError: LocalizedError {
    var str: String

    var errorDescription: String? {
        return "Invalid format for string: \(self.str)."
    }
    var failureReason: String? { return self.errorDescription }

    init(str: String) {
        self.str = str
    }
}

extension DateComponents {

    /**
     Convert a string to DateComponents if the string conforms to one of these ISO_8601 formats: PnYnMnDTnHnMnS or PnW.
     Decimal values are not supported, although they are allowed in the ISO_8601 specification.

     Examples:
     1.) PT11H = 11 hours
     2.) P2D = 2 days
     3.) P1DT2H = 1 days, 2 hours
     4.) P2Y4M3DT8H30M3S = 2 years, 4 months, 3 days, 8 hours, 30 minutes and 3 seconds
     5.) P8W = 56 days

     - Parameter from: PnYnMnDTnHnMnS or PnW formatted string
     - Return DateComponents

     - Throws InvalidFormatError: if the string has an invalid format
     */
    static func from(iso8601String: String) throws -> DateComponents {
        guard let pIndex = iso8601String.firstIndex(of: "P") else {
            throw InvalidFormatError(str: iso8601String)
        }

        var dateComponents = DateComponents()
        let durationString = String(iso8601String[iso8601String.index(after: pIndex)...])

        // Format: PnW
        // Just calculate the current day and exit.
        if iso8601String.contains("W") {
            let weekValues = try components(for: durationString, designatorSet: CharacterSet(charactersIn: "W"))
            if let weekValue = weekValues["W"] {
                dateComponents.day = Int(weekValue.doubleValue! * 7.0)
            }
            return dateComponents
        }

        let comp = durationString.split(separator: "T", maxSplits: 1, omittingEmptySubsequences: false)
        let periodString = String(comp.first!)
        let timeString = String(comp.last!)

        // Partial format: DnMnYn
        let periodValues = try components(for: periodString, designatorSet: CharacterSet(charactersIn: "YMD"))
        dateComponents.day = periodValues["D"]?.intValue
        dateComponents.month = periodValues["M"]?.intValue
        dateComponents.year = periodValues["Y"]?.intValue

        // Partial format: SnMnHn
        let timeValues = try components(for: timeString, designatorSet: CharacterSet(charactersIn: "HMS"))
        dateComponents.second = timeValues["S"]?.intValue
        dateComponents.minute = timeValues["M"]?.intValue
        dateComponents.hour = timeValues["H"]?.intValue

        return dateComponents
    }

    fileprivate static func components(for string: String, designatorSet: CharacterSet) throws -> [String: String] {
        guard !string.isEmpty else { return [:] }

        let desigValues = string.components(separatedBy: .decimalDigits).filter { !$0.isEmpty }
        let compValues = string.components(separatedBy: designatorSet).filter { !$0.isEmpty }
        if compValues.count == desigValues.count {
            return Dictionary(uniqueKeysWithValues: zip(desigValues, compValues))
        }

        throw InvalidFormatError(str: string)
    }

    /**
     Convert the datecomponents to P[n]Y[n]M[n]DT[n]H[n]M[n]S.
     */
    func iso8601String() -> String {
        //P2Y4M3DT8H30M3S
        var str = "P"
        for (comp, letter)  in [(self.year, "Y"), (self.month, "M"), (self.day, "D")] {
            if let comp = comp {
                str += "\(comp)\(letter)"
            }
        }
        str += "T"
        for (comp, letter)  in [(self.hour, "H"), (self.minute, "M"), (self.second, "S")] {
            if let comp = comp {
                str += "\(comp)\(letter)"
            }
        }
        return str
    }
}
