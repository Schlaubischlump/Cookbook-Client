//
//  Array.swift
//  Cookbook
//
//  Created by David Klopp on 01.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation

extension Array {
    /**
     Filter an array based on a boolean mask.
     - Parameter mask: Array to filter
     - Return: filtered array
     */
    func booleanMask(_ mask: [Bool]) -> Array {
        return zip(mask, self).filter { $0.0 }.map { $1 }
    }
}
