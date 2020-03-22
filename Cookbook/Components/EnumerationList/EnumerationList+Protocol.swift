//
//  EnumerationListDelegate.swift
//  Cookbook
//
//  Created by David Klopp on 22.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import CoreGraphics

/**
 Delegate to get informed if the EnumerationList height changes.
 */
protocol EnumerationListDelegate: AnyObject {
    func enumerationList(_ list: EnumerationList, heightChanged: CGFloat)
}
