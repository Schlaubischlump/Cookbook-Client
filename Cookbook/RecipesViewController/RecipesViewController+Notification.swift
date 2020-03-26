//
//  RecipesViewController+Notification.swift
//  Cookbook
//
//  Created by David Klopp on 20.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//
// If you ask yourself, why the fuck does he use notifications to delete and add recipes...
// The answer is: Because we want the changes to be synchronised between mutliple windows.

import Foundation
import UIKit

extension RecipesViewController {

    // MARK: - Helper

    /**
     Start listening for incoming notifications.
     */
    func registerNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.didRemoveRecipe), name: .didRemoveRecipe, object: nil)
        center.addObserver(self, selector: #selector(self.didLoadRecipes), name: .didLoadRecipes, object: nil)
        center.addObserver(self, selector: #selector(self.showLoginPrompt), name: .showLoginPrompt, object: nil)
        center.addObserver(self, selector: #selector(self.didEditRecipe), name: .didEditRecipe, object: nil)
        center.addObserver(self, selector: #selector(self.didAddRecipe), name: .didAddRecipe, object: nil)
        center.addObserver(self, selector: #selector(self.didAttemptLogin), name: .login, object: nil)
        center.addObserver(self, selector: #selector(self.requestReload), name: .reload, object: nil)
        center.addObserver(self, selector: #selector(self.didLogout), name: .logout, object: nil)
    }

    /**
     Stop listening for notifications.
     */
    func deregisterNotifications() {
        let center = NotificationCenter.default
        center.removeObserver(self, name: .didRemoveRecipe, object: nil)
        center.removeObserver(self, name: .didLoadRecipes, object: nil)
        center.removeObserver(self, name: .showLoginPrompt, object: nil)
        center.removeObserver(self, name: .didEditRecipe, object: nil)
        center.removeObserver(self, name: .didAddRecipe, object: nil)
        center.removeObserver(self, name: .login, object: nil)
        center.removeObserver(self, name: .logout, object: nil)
        center.removeObserver(self, name: .reload, object: nil)
    }

    // MARK: - Notification handling

    /// Called after a login attempt.
    @objc func didAttemptLogin(_ notification: Notification) {
        self.reloadData(useCachedData: false)
    }

    /// Called after a successfull logout.
    @objc func didLogout(_ notification: Notification) {
        self.recipes = []
        self.filteredRecipes = []
        self.reloadData(useCachedData: true)
        self.showNextcloudLogin()
    }

    /// Callback when a reload is forced with a notification.
    @objc func requestReload(_ notification: Notification) {
        self.reloadData(useCachedData: false)
    }

    /// Called when a reload operation finishes.
    @objc func didLoadRecipes(_ notification: Notification) {
        // If we just created a new recipe
        guard let sender = notification.object as? RecipesViewController, sender.newRecipeController != nil else {
            return
        }

        // In case of the active window, dismiss the newRecipeController.
        if self == sender {
            self.dismiss(animated: true)
            // We might need to reactivate the searchController.
            if !(self.searchController.searchBar.text?.isEmpty ?? true) {
                self.present(self.searchController, animated: false)
            }
        }
    }

    /// Called when the login prompt is displayed.
    @objc func showLoginPrompt(_ notification: Notification) {
        // Reset the search.
        self.searchController.searchBar.text = ""
        self.searchController.isActive = false

        // Open the sidebar to prevent a disabled window state on macOS.
        let splitViewController = self.splitViewController as? SplitViewController
        if splitViewController?.displayMode != .allVisible {
            splitViewController?.toggleSidebar()
        }
    }

    /// Called when a new recipe was added.
    @objc func didAddRecipe(_ notification: Notification) {
        // We only want to reload if we successfully added the recipe.
        guard notification.userInfo?["recipeID"] != nil else { return }
        // Reload the data from the server.
        self.reloadData(useCachedData: false)
    }

    /// Called when a recipe was sucessfully edited.
    @objc func didEditRecipe(_ notification: Notification) {
        if let recipeID = notification.userInfo?["recipeID"] as? Int,
           let recipeDetails = notification.userInfo?["details"] as? [String: Any] {

            // Check if the edited recipe is visible. Depending on the active window this might not be the case.
            // If we selected an item and start searching this might also be the case.
            var recipe: Recipe?
            if let row = self.filteredRecipes.firstIndex(where: { $0.recipeID == recipeID }) {
                recipe = self.filteredRecipes[row]
            } else {
                recipe = self.recipes.first(where: { $0.recipeID == recipeID })
            }

            // We need to update the recipe name because otherwise the search update will not work.
            if let name = recipeDetails["name"] as? String {
                recipe?.name = name
            }

            // Update the currently displayed information, including the recipe name and image.
            self.updateSearchResults()
        }
    }

    /// Called when a recipe is deleted.
    @objc func didRemoveRecipe(_ notification: Notification) {
        guard let recipeID = notification.userInfo?["recipeID"] as? Int else { return }
        // Find the index of the recipe to delete
        if let index = self.recipes.firstIndex(where: { $0.recipeID == recipeID }) {
            self.recipes.remove(at: index)
            self.updateSearchResults()
        }
    }
}
