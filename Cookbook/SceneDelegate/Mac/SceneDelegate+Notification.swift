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
    private func setToolbarItemsEnabled(_ enabled: Bool) {
        guard let scene = self.window?.windowScene else { return }

        #if targetEnvironment(macCatalyst)
        if let toolbarItems = scene.titlebar?.toolbar?.items {
            toolbarItems.forEach { item in
                item.isEnabled = enabled
            }
        }
        #endif
    }

    /// Disable toolbar items when a HUD is displayed.
    @objc func willLoadRecipes(_ notification: Notification) {
        self.setToolbarItemsEnabled(false)
    }

    /// Enable toolbar items when all recipes are loaded from the server.
    @objc func didLoadRecipes(_ notification: Notification) {
        guard let scene = self.window?.windowScene else { return }

        #if targetEnvironment(macCatalyst)
        if let toolbarItems = scene.titlebar?.toolbar?.items {
            toolbarItems.forEach { item in
                let enabled = item.itemIdentifier != UIBarButtonItem.Kind.share.identifier &&
                              item.itemIdentifier != UIBarButtonItem.Kind.edit.identifier &&
                              item.itemIdentifier != UIBarButtonItem.Kind.delete.identifier
                item.isEnabled = enabled
            }
        }
        #endif
    }

    /// Called when the recipe details start loading from the server.
    @objc func willLoadRecipeDetails(_ notification: Notification) {
        guard let scene = self.window?.windowScene else { return }

        #if targetEnvironment(macCatalyst)
        if let toolbarItems = scene.titlebar?.toolbar?.items {
            toolbarItems.forEach { item in
                let enabled = item.itemIdentifier != UIBarButtonItem.Kind.share.identifier &&
                              item.itemIdentifier != UIBarButtonItem.Kind.edit.identifier &&
                              item.itemIdentifier != UIBarButtonItem.Kind.delete.identifier
                item.isEnabled = enabled
            }
        }
        #endif
    }

    /// Called when the recipe details finished loading from the server.
    @objc func didLoadRecipeDetails(_ notification: Notification) {
        self.setToolbarItemsEnabled(true)
    }

    /// Called after a successfull logout.
    @objc func didLogout(_ notification: Notification) {
        self.setToolbarItemsEnabled(false)
    }

    /// Called after a successfull logout.
    @objc func didLogin(_ notification: Notification) {
        self.setToolbarItemsEnabled(false)
    }

    /// Called before the update operartion is send to the server.
    @objc func willEditRecipe(_ notification: Notification) {
        self.setToolbarItemsEnabled(false)
    }

    /// Called after the edit operation was send to the server (this includes the case when an error occured).
    @objc func didEditRecipe(_ notification: Notification) {
        self.setToolbarItemsEnabled(true)
    }
}
