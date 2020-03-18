//
//  UIImage.swift
//  Cookbook
//
//  Created by David Klopp on 16.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    static func toolbarImage(_ systemName: String) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(weight: .regular)
        let tintColor = UIColor(displayP3Red: 86/255.0, green: 86/255.0, blue: 86/255.0, alpha: 1.0)
        var image = UIImage(systemName: systemName, withConfiguration: configuration)
        image = image?.withTintColor(tintColor)
        return image?.af_imageAspectScaled(toFit: CGSize(width: 44, height: 44))
    }
}
