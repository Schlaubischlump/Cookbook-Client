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

    // MARK: - Helper

    /**
     Setup the window tool- and titlebar.
     */
    func setupToolbar() {
        guard let titlebar = self.window?.windowScene?.titlebar else { return }

        let toolbar = NSToolbar(identifier: "toolbar")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = true
        toolbar.displayMode = .iconOnly
        titlebar.autoHidesToolbarInFullScreen = true

        titlebar.titleVisibility = .hidden
        titlebar.toolbar = toolbar
    }

    /**
     A list with all toolbar items added to this window.
     - Return: list with `NSToolbarItem`
     */
    var toolbarItems: [NSToolbarItem]? {
        return self.window?.windowScene?.titlebar?.toolbar?.items
    }

    /**
     Get the first toolbar item of this window which has the specified `UIBarButtonItem.Kind`. This function assumes
     that you do not add more then whan toolbar item with the same `UIBarButtonItem.Kind` to the window.
     - Parameter item: the specific bar button item kind
     - Return: first `NSToolbarItem` which machtes the `UIBarButtonItem.Kind`
     */
    func getToolbarItem(_ item: UIBarButtonItem.Kind) -> NSToolbarItem? {
        return self.toolbarItems?.first(where: { $0.itemIdentifier ==  item.identifier})
    }

    /**
     Enable or disable all toolbar items which match the specified `UIBarButtonItem.Kind` identifiers.
     - Parameter enabled: true to enable or false to disable the items
     - Parameter buttonKind: list with `UIBarButtonItem.Kind` to filter the NSToolbarItems
     */
    func setToolbarItemsEnabled(_ enabled: Bool, buttonKind: [UIBarButtonItem.Kind]? = nil) {
        if let toolbarItems = self.toolbarItems {
            toolbarItems.forEach { item in
                if buttonKind?.contains(where: { $0.identifier == item.itemIdentifier }) ?? true {
                    item.isEnabled = enabled
                }
            }
        }
    }

    /**
     Callback function when a toolbar item is clicked. Call the corresponding function based on the itemIdentifier.
     - Parameter sender: clicked NSToolbarItem.
     */
    @objc func toolbarItemClicked(_ sender: Any) {
        guard let splitViewController = self.window?.rootViewController as? SplitViewController else { return }

        switch (sender as? NSToolbarItem)?.itemIdentifier {
        case UIBarButtonItem.Kind.share.identifier:
            splitViewController.recipeDetailController?.shareRecipe(item: sender)
        case UIBarButtonItem.Kind.edit.identifier:
            splitViewController.recipeDetailController?.editRecipe(item: sender)
        case UIBarButtonItem.Kind.delete.identifier:
            splitViewController.recipeDetailController?.deleteRecipe(item: sender)
        case UIBarButtonItem.Kind.add.identifier:
            splitViewController.recipesMasterController?.addRecipe(item: sender)
        case UIBarButtonItem.Kind.sidebar.identifier:
            splitViewController.toggleSidebar(item: sender)
        default: break
        }
    }

    // MARK: - NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        guard let barType = UIBarButtonItem.Kind(value: itemIdentifier.rawValue) else { return nil }

        let item = UIBarButtonItem.with(kind: barType)
        item.target = self
        item.action = #selector(self.toolbarItemClicked(_ :))
        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: item)
        toolbarItem.autovalidates = false
        toolbarItem.isEnabled = false
        toolbarItem.paletteLabel = barType.paletteLabel
        toolbarItem.label = barType.paletteLabel
        toolbarItem.toolTip = barType.paletteLabel
        return toolbarItem
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [UIBarButtonItem.Kind.sidebar.identifier,
                UIBarButtonItem.Kind.add.identifier,
                UIBarButtonItem.Kind.delete.identifier,
                UIBarButtonItem.Kind.edit.identifier,
                NSToolbarItem.Identifier.flexibleSpace,
                UIBarButtonItem.Kind.share.identifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }
}
