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
        let image = UIImage(systemName: systemName, withConfiguration: configuration)
        return image?.af_imageAspectScaled(toFit: CGSize(width: 44, height: 44)).withRenderingMode(.alwaysTemplate)
    }
}
