//
//  SceneDelegate+Notification.swift
//  Cookbook
//
//  Created by David Klopp on 18.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension SceneDelegate {
    /// Disable toolbar items when a HUD is displayed.
    @objc func showHUD(_ notification: Notification) {
        guard let scene = self.window?.windowScene else { return }

        #if targetEnvironment(macCatalyst)
        if let toolbarItems = scene.titlebar?.toolbar?.items {
            toolbarItems.filter { $0.itemIdentifier != BarButtonItemType.sidebar.identifier }.forEach { item in
                item.isEnabled = false
            }
        }
        #endif
    }

    /// Enable toolbar items when a HUD is displayed.
    @objc func hideHUD(_ notification: Notification) {
        guard let scene = self.window?.windowScene else { return }

        #if targetEnvironment(macCatalyst)
        if let toolbarItems = scene.titlebar?.toolbar?.items {
            toolbarItems.filter { $0.itemIdentifier != BarButtonItemType.sidebar.identifier }.forEach { item in
                item.isEnabled = true
            }
        }
        #endif
    }

    /// Called when the recipe details start loading from the server.
    @objc func willLoadRecipeDetails(_ notification: Notification) {
        guard let scene = self.window?.windowScene else { return }

        #if targetEnvironment(macCatalyst)
        if let toolbarItems = scene.titlebar?.toolbar?.items {
            toolbarItems.filter {
                $0.itemIdentifier == BarButtonItemType.share.identifier ||
                $0.itemIdentifier == BarButtonItemType.edit.identifier ||
                $0.itemIdentifier == BarButtonItemType.delete.identifier
            }.forEach { item in
                item.isEnabled = false
            }
        }
        #endif
    }

    /// Called when the recipe details finished loading from the server.
    @objc func didLoadRecipeDetails(_ notification: Notification) {
        guard let scene = self.window?.windowScene else { return }

        #if targetEnvironment(macCatalyst)
        if let toolbarItems = scene.titlebar?.toolbar?.items {
            toolbarItems.filter {
                $0.itemIdentifier == BarButtonItemType.share.identifier ||
                $0.itemIdentifier == BarButtonItemType.edit.identifier ||
                $0.itemIdentifier == BarButtonItemType.delete.identifier
            }.forEach { item in
                item.isEnabled = true
            }
        }
        #endif
    }
}
