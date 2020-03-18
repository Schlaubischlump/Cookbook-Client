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

        guard let barType = BarButtonItemType(rawValue: itemIdentifier.rawValue) else { return nil }

        let item = BarButtonItem.with(type: barType)
        item.target = self
        item.action = #selector(self.toolbarItemClicked(_ :))
        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: item)
        toolbarItem.autovalidates = false
        toolbarItem.paletteLabel = barType.paletteLabel
        toolbarItem.label = barType.paletteLabel
        return toolbarItem
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [BarButtonItemType.sidebar.identifier,
                BarButtonItemType.add.identifier,
                BarButtonItemType.delete.identifier,
                BarButtonItemType.edit.identifier,
                NSToolbarItem.Identifier.flexibleSpace,
                BarButtonItemType.share.identifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }

    // MARK: - Helper

    // Callback function when a toolbar item is clicked.
    @objc func toolbarItemClicked(_ sender: Any) {
        guard let splitViewController = self.window?.rootViewController as? SplitViewController else { return }

        switch (sender as? NSToolbarItem)?.itemIdentifier {
        case BarButtonItemType.share.identifier:
            splitViewController.recipeDetailController?.shareRecipe(item: sender)
        case BarButtonItemType.edit.identifier:
            splitViewController.recipeDetailController?.editRecipe(item: sender)
        case BarButtonItemType.delete.identifier:
            splitViewController.recipeDetailController?.deleteRecipe(item: sender)
        case BarButtonItemType.add.identifier:
            splitViewController.recipesMasterController?.addRecipe(item: sender)
        case BarButtonItemType.sidebar.identifier:
            splitViewController.toggleSidebar(item: sender)
        default: break
        }
    }
}
