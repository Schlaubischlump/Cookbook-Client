//
//  SceneDelegate+ToolbarMac.swift
//  Cookbook
//
//  Created by David Klopp on 14.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension SceneDelegate: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let window = window else { return nil }
        guard let splitViewController = window.rootViewController as? UISplitViewController else { return nil }
        guard let navigationController = splitViewController.viewControllers.first as? UINavigationController else {
            return nil
        }
        guard let masterController = navigationController.topViewController as? RecipesViewController else { return nil}

        if let barType = BarButtonType(rawValue: itemIdentifier.rawValue),
            let item = masterController.barButtonForType(barType) {
            let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: item)
            toolbarItem.paletteLabel = barType.paletteLabel
            toolbarItem.label = barType.paletteLabel
            return toolbarItem
        }

        return nil
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [BarButtonType.sidebar.identifier,
                NSToolbarItem.Identifier.flexibleSpace,
                BarButtonType.share.identifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }
}
