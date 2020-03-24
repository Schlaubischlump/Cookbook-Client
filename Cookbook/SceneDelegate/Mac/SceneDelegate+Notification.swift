//
//  SceneDelegate+Notification.swift
//  Cookbook
//
//  Created by David Klopp on 18.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//
// This file extension responsible for enabling and disabling the toolbar items when different event occur.
// Sometimes the changes should only be applied to the currently active window. In this case you have to compare
// the notification senders delegate to this delegate and only apply the changes if both match.

import Foundation
import UIKit

extension SceneDelegate {
    // MARK: - Register / unregister Notifications

    /**
     Register notification center events to enable / disable the toolbar items when needed.
     */
    func registerNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(willLoadRecipes), name: .willLoadRecipes, object: nil)
        center.addObserver(self, selector: #selector(didLoadRecipes), name: .didLoadRecipes, object: nil)
        center.addObserver(self, selector: #selector(didLogout), name: .logout, object: nil)
        center.addObserver(self, selector: #selector(didLogin), name: .login, object: nil)
        center.addObserver(self, selector: #selector(willLoadRecipeDetails), name: .willLoadRecipeDetails, object: nil)
        center.addObserver(self, selector: #selector(didLoadRecipeDetails), name: .didLoadRecipeDetails, object: nil)
        center.addObserver(self, selector: #selector(willAddRecipe), name: .willAddRecipe, object: nil)
        center.addObserver(self, selector: #selector(didAddRecipe), name: .didAddRecipe, object: nil)
        center.addObserver(self, selector: #selector(willEditRecipe), name: .willEditRecipe, object: nil)
        center.addObserver(self, selector: #selector(didEditRecipe), name: .didEditRecipe, object: nil)
        center.addObserver(self, selector: #selector(didRemoveRecipe), name: .didRemoveRecipe, object: nil)
    }

    /**
     Stop listening for notifications.
     */
    func deregisterNotifications() {
        let center = NotificationCenter.default
        center.removeObserver(self, name: .willLoadRecipes, object: nil)
        center.removeObserver(self, name: .didLoadRecipes, object: nil)
        center.removeObserver(self, name: .logout, object: nil)
        center.removeObserver(self, name: .login, object: nil)
        center.removeObserver(self, name: .willLoadRecipeDetails, object: nil)
        center.removeObserver(self, name: .didLoadRecipeDetails, object: nil)
        center.removeObserver(self, name: .willEditRecipe, object: nil)
        center.removeObserver(self, name: .didEditRecipe, object: nil)
        center.removeObserver(self, name: .willAddRecipe, object: nil)
        center.removeObserver(self, name: .didAddRecipe, object: nil)
        center.removeObserver(self, name: .didRemoveRecipe, object: nil)
    }

    // MARK: - Notification Callbacks to handle the toolbar

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

        // We might need to disable a couple of buttons if we are currently in edit mode.
        let splitViewController = recipesMaster?.splitViewController as? SplitViewController
        let isEditing = splitViewController?.recipeDetailController?.isEditable
        if isEditing ?? false {
            self.setToolbarItemsEnabled(false, buttonKind: [UIBarButtonItem.Kind.add, UIBarButtonItem.Kind.share,
                                                            UIBarButtonItem.Kind.delete])
        }

        // If we deleted the last recipe or we start without a recipe we need to disable the edit, delete and
        // share button.
        if recipesMaster?.recipes.isEmpty ?? true {
            self.setToolbarItemsEnabled(false, buttonKind: [UIBarButtonItem.Kind.edit, UIBarButtonItem.Kind.share,
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
        let detailController = (notification.object as? RecipeDetailViewController)
        let window = detailController?.view.window
        guard self == window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        self.setToolbarItemsEnabled(true)

        // Just in case if we are in edit mode.
        if detailController?.isEditable ?? false {
            self.setToolbarItemsEnabled(false, buttonKind: [UIBarButtonItem.Kind.add, UIBarButtonItem.Kind.share,
                                                            UIBarButtonItem.Kind.delete])
        }

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

        let editItem = self.getToolbarItem(UIBarButtonItem.Kind.edit)
        editItem?.image = .toolbarImage(kDoneToolbarImage)
    }

    /// Called after the edit operation was send to the server (this includes the case when an error occured).
    @objc func didEditRecipe(_ notification: Notification) {
        let window = (notification.object as? RecipeDetailViewController)?.view.window
        guard self == window?.windowScene?.delegate as? SceneDelegate else {
            return
        }
        self.setToolbarItemsEnabled(true)
        let editItem = self.getToolbarItem(UIBarButtonItem.Kind.edit)
        editItem?.image = .toolbarImage(kEditToolbarImage)
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

    /// Called after an item is deleted.
    @objc func didRemoveRecipe(_ notification: Notification) {
        // We need to perform this action for all windows. That means we don't need to compare the sender.
        guard notification.userInfo?["recipeID"] != nil else { return }
        guard let splitViewController = self.window?.rootViewController as? SplitViewController else { return }

        // Disable all toolbar items when we delete the last recipe.
        // We can not guarantee that this method is called before the RecipesViewController deletes the recipe entry
        // from its list, but we can guarantee that the list is empty, if a recipe was deleted (`recipeID` != nil)
        // and the recipe list contained less than 2 elements.
        if splitViewController.recipesMasterController?.recipes.count ?? 0 <= 1 {
            self.setToolbarItemsEnabled(false)
            self.setToolbarItemsEnabled(true, buttonKind: [UIBarButtonItem.Kind.sidebar, UIBarButtonItem.Kind.add])
        }
    }
}
