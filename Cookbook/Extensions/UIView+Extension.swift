//
//  UIView.swift
//  Cookbook
//
//  Created by David Klopp on 01.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

extension UIView {
    func pdfData() -> Data? {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, self.bounds, nil)
        UIGraphicsBeginPDFPage()

        guard let pdfContext = UIGraphicsGetCurrentContext() else { return nil }
        pdfContext.interpolationQuality = .high

        self.drawHierarchy()

        UIGraphicsEndPDFContext()

        return Data(pdfData)
    }

    /// Helper for highresolution pdf rendering.
    func drawHierarchy() {
        self.layoutSubviews()

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.translateBy(x: self.frame.origin.x, y: self.frame.origin.y)

        if let bgColor = self.backgroundColor {
            context?.setFillColor(bgColor.cgColor)
            context?.fill(self.bounds)
        }

        self.draw(self.bounds)

        if self.clipsToBounds {
            context?.clip(to: self.bounds)
        }

        self.subviews.filter { !$0.isHidden }.forEach { $0.drawHierarchy() }

        context?.restoreGState()
    }
}
