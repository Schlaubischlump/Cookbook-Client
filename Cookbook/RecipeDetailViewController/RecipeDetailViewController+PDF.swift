//
//  RecipeDetailViewController+PDF.swift
//  Cookbook
//
//  Created by David Klopp on 15.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension RecipeDetailViewController {
    /**
     Create a pdf representation of the recipe currently displayed. Always use a light design.
     This will generate a warning about autolayout, because we render the view offscreen.
    */
    func pdfRepresentation() -> Data? {
        let a4PageWidth: CGFloat = 595

        // Create a dummy container to add all the relevant subviews.
        let container = UIView(frame: .zero)
        container.backgroundColor = .white
        var height: CGFloat = parallaxHeaderImageView?.bounds.height ?? 0

        // Add our lists and our image to the container view.
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: a4PageWidth, height: height))
        imageView.image = parallaxHeaderImageView?.image?.af_imageAspectScaled(toFill: imageView.bounds.size)
        container.addSubview(imageView)

        for list in [self.descriptionList, self.toolsList, self.ingredientsList, self.instructionsList] {
            guard let enumList = list else { return nil }

            var frame = CGRect(x: 0, y: height, width: a4PageWidth, height: CGFloat.greatestFiniteMagnitude)
            let enumListCopy = EnumerationList(frame: frame, style: .insetGrouped)
            container.addSubview(enumListCopy)

            enumListCopy.overrideUserInterfaceStyle = .light
            enumListCopy.separatorStyle = .none
            enumListCopy.title = enumList.title
            enumListCopy.backgroundColor = .white
            enumListCopy.enumerationStyle = enumList.enumerationStyle
            enumListCopy.data = enumList.data

            frame.size.height = enumListCopy.contentSize.height
            enumListCopy.frame = frame

            height += enumListCopy.frame.height
        }

        // Layout the view.
        container.frame = CGRect(x: 0, y: 0, width: a4PageWidth, height: height)
        for list in [self.descriptionList, self.toolsList, self.ingredientsList, self.instructionsList] {
            list?.visibleCells.forEach { $0.textLabel?.textColor = .blue }
        }

        // Return the pdfData of the view.
        return container.pdfData()
    }
}
