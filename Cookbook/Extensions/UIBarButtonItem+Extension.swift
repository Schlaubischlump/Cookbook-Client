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

/**
 Create an instance of a specified UIBarButton item which can be used in a NSToolbar or a UIToolbar / UINavigationBar.
 - Parameter identifier: type of the UIBarButton to use (See BarButtonType)
 - Return: instance of the UIBarButton
 */

extension UIBarButtonItem {

    public enum Kind {
        case share
        case edit
        case delete
        case add
        case save
        case cancel
        #if targetEnvironment(macCatalyst)
        // mac only
        case sidebar
        case fakeTitle(_ title: String = "")
        #else
        // iOS only
        case done
        case settings
        #endif

        var value: String {
            switch self {
            case .share:  return "SHARE"
            case .edit:   return "EDIT"
            case .delete: return "DELETE"
            case .add:    return "ADD"
            case .save:   return "SAVE"
            case .cancel: return "CANCEL"

            #if targetEnvironment(macCatalyst)
            // mac only
            case .sidebar:   return "TOGGLE_SIDEBAR"
            case .fakeTitle: return "FAKE_TITLE"
            #else
            // iOS only
            case .done:     return "DONE"
            case .settings: return "SETTINGS"
            #endif
            }
        }

        // swiftlint:disable cyclomatic_complexity
        init?(value: String) {
            switch value {
            case "SHARE":  self = .share
            case "EDIT":   self = .edit
            case "DELETE": self = .delete
            case "ADD":    self = .add
            case "SAVE":   self = .save
            case "CANCEL": self = .cancel

            #if targetEnvironment(macCatalyst)
            // mac only
            case "TOGGLE_SIDEBAR": self = .sidebar
            case "FAKE_TITLE":     self = .fakeTitle("")
            #else
            // iOS only
            case "DONE":     self = .done
            case "SETTINGS": self = .settings
            #endif

            default: return nil
            }
        }
        // swiftlint:enable cyclomatic_complexity

        #if targetEnvironment(macCatalyst)
        var identifier: NSToolbarItem.Identifier { return NSToolbarItem.Identifier(rawValue: self.value) }
        var paletteLabel: String { return NSLocalizedString(self.value + "_PALETTE_LABEL", comment: "") }
        #endif
    }

    static func with(kind: UIBarButtonItem.Kind, target: AnyObject? = nil, action: Selector? = nil) -> UIBarButtonItem {
        var item: UIBarButtonItem?
        switch kind {
        case .share:
            item = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
        case .edit:
            #if targetEnvironment(macCatalyst)
            item = UIBarButtonItem(image: .toolbarImage(kEditToolbarImage), style: .plain, target: nil, action: nil)
            #else
            item = UIBarButtonItem(barButtonSystemItem: .compose, target: nil, action: nil)
            #endif
        case .delete:
            item = UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
        case .add:
            item = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        case .save:
            item = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
        case .cancel:
            item = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        #if targetEnvironment(macCatalyst)
        case .sidebar:
            item = UIBarButtonItem(image: .toolbarImage("sidebar.left"), style: .plain, target: nil, action: nil)
        case .fakeTitle(let title):
            let label = UILabel()
            label.text = title
            label.textColor = .gray
            label.font = .systemFont(ofSize: UIFont.labelFontSize, weight: .semibold)
            item = UIBarButtonItem(customView: label)
        #else
        case .done:
            item = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        case .settings:
            let configuration = UIImage.SymbolConfiguration(weight: .black)
            let image = UIImage(systemName: "gear", withConfiguration: configuration)
            item = UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
        #endif

        }

        item?.target = target
        item?.action = action
        return item!
    }
}
