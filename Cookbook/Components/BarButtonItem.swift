//
//  UIBarButtonItem+Extension.swift
//  Cookbook
//
//  Created by David Klopp on 17.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

/**
 Enum to represent the different kind of UIBarButtonItems.
 */
let kEditToolbarImage = "square.and.pencil"
let kDoneToolbarImage = "checkmark.square"

enum BarButtonItemType: String {
    case share = "SHARE"
    case edit = "EDIT"
    case delete = "DELETE"
    case add = "ADD"
    case settings = "SETTINGS" // used for iOS only
    case sidebar = "TOGGLE_SIDEBAR" // used for Mac only

    #if targetEnvironment(macCatalyst)
    var identifier: NSToolbarItem.Identifier { return NSToolbarItem.Identifier(rawValue: self.rawValue) }
    var paletteLabel: String { return NSLocalizedString(self.rawValue + "_PALETTE_LABEL", comment: "") }
    #endif
}

/**
 Create an instance of a specified UIBarButton item which can be used in a NSToolbar or a UIToolbar / UINavigationBar.
 - Parameter identifier: type of the UIBarButton to use (See BarButtonType)
 - Return: instance of the UIBarButton
 */

class BarButtonItem: UIBarButtonItem {
    private var barType: BarButtonItemType?

    static func with(type: BarButtonItemType) -> BarButtonItem {
        var item: BarButtonItem?

        switch type {
        case .share:
            item = BarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
        case .edit:
            #if targetEnvironment(macCatalyst)
            item = BarButtonItem(image: .toolbarImage(kEditToolbarImage), style: .plain, target: nil, action: nil)
            #else
            item = BarButtonItem(barButtonSystemItem: .compose, target: nil, action: nil)
            #endif
        case .delete:
            item = BarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
        case .add:
            item = BarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        case .settings:
            let configuration = UIImage.SymbolConfiguration(weight: .black)
            let image = UIImage(systemName: "gear", withConfiguration: configuration)
            item = BarButtonItem(image: image, style: .plain, target: nil, action: nil)
        case .sidebar:
            item = BarButtonItem(image: .toolbarImage("sidebar.left"), style: .plain, target: nil, action: nil)
        }

        item?.barType = type

        return item!
    }
}
