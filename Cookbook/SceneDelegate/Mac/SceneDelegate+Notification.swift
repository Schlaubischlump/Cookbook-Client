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
    private func setToolbarItemsEnabled(_ enabled: Bool, buttonKind: [UIBarButtonItem.Kind]? = nil) {
        guard let scene = self.window?.windowScene else { return }

        #if targetEnvironment(macCatalyst)
        if let toolbarItems = scene.titlebar?.toolbar?.items {
            toolbarItems.forEach { item in
                if buttonKind?.contains(where: { $0.identifier == item.itemIdentifier }) ?? true {
                    item.isEnabled = enabled
                }
            }
        }
        #endif
    }

    /// Disable toolbar items when we begin to load the data from the server.
    @objc func willLoadRecipes(_ notification: Notification) {
        let window = (notification.object as? RecipesViewController)?.view.window
        guard self == window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        self.setToolbarItemsEnabled(false)
    }

    /// Enable toolbar items when all recipes are loaded from the server.
    @objc func didLoadRecipes(_ notification: Notification) {
        let recipesMaster = (notification.object as? RecipesViewController)
        let window = recipesMaster?.view.window
        guard self == window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        self.setToolbarItemsEnabled(true)

        let splitViewController = recipesMaster?.splitViewController as? SplitViewController
        let isEditing = splitViewController?.recipeDetailController?.isEditable
        if isEditing ?? false {
            self.setToolbarItemsEnabled(false, buttonKind: [UIBarButtonItem.Kind.add, UIBarButtonItem.Kind.share,
                                                            UIBarButtonItem.Kind.delete])
        }
    }

    /// Called when the recipe details start loading from the server.
    @objc func willLoadRecipeDetails(_ notification: Notification) {
        let window = (notification.object as? RecipeDetailViewController)?.view.window
        guard self == window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        self.setToolbarItemsEnabled(false)
        self.setToolbarItemsEnabled(true, buttonKind: [UIBarButtonItem.Kind.sidebar])
    }

    /// Called when the recipe details finished loading from the server.
    @objc func didLoadRecipeDetails(_ notification: Notification) {
        let window = (notification.object as? RecipeDetailViewController)?.view.window
        guard self == window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
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

    /// Called when the user starts editing the recipe.
    @objc func willEditRecipe(_ notification: Notification) {
        let window = (notification.object as? RecipeDetailViewController)?.view.window
        guard self == window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        self.setToolbarItemsEnabled(false)
        self.setToolbarItemsEnabled(true, buttonKind: [UIBarButtonItem.Kind.edit, UIBarButtonItem.Kind.sidebar])
    }

    /// Called after the edit operation was send to the server (this includes the case when an error occured).
    @objc func didEditRecipe(_ notification: Notification) {
        let window = (notification.object as? RecipeDetailViewController)?.view.window
        guard self == window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        self.setToolbarItemsEnabled(true)
    }

    /// Called when the user wants to add a new recipe.
    @objc func willAddRecipe(_ notification: Notification) {
        let window = (notification.object as? RecipesViewController)?.view.window
        guard self == window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        self.setToolbarItemsEnabled(false)
        self.setToolbarItemsEnabled(true, buttonKind: [UIBarButtonItem.Kind.sidebar])
    }

    /// Called when the user did add a new recipe.
    @objc func didAddRecipe(_ notification: Notification) {
        let window = (notification.object as? RecipesViewController)?.view.window
        guard self == window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        self.setToolbarItemsEnabled(true)
    }
}
