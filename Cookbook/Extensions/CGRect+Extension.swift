//
//  CGRect+Extension.swift
//  Cookbook
//
//  Created by David Klopp on 24.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGRect {
    // Add the padding to each side of the given frame
    init(rect: CGRect, padding pad: CGFloat) {
        self = CGRect(x: rect.minX-pad, y: rect.minY-pad, width: rect.width+2*pad, height: rect.height+2*pad)
    }
}
