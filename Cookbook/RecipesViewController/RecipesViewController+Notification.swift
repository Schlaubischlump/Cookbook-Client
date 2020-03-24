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
            // Save the current seach text.
            let searchText = self.searchController.searchBar.text ?? ""
            // Check if the edited recipe is visible. Depending on the active window this might not be the case.
            // If we selected an item and start searching this might also be the case.
            let index = self.filteredRecipes.firstIndex(where: { $0.recipeID == recipeID })

            guard let row = index else {
                // We need to update the name, otherwise we are working on outdated data. Everything else can not be
                // edited, or belongs to the recipe details and is managed by the RecipeDetailViewController.
                if let name = recipeDetails["name"] as? String,
                   let recipe = self.recipes.first(where: { $0.recipeID == recipeID }) {
                    recipe.name = name
                }
                // If we changed the name of the current recipe to one that matches the search string, we need to
                // reload the table to make it visible.
                if !searchText.isEmpty {
                    self.updateSearchResults()
                }
                return
            }

            // Get a reference to the active cell.
            let indexPath = IndexPath(row: row, section: 0)
            let cell = self.tableView.cellForRow(at: indexPath) as? RecipesTableViewCell
            let recipe = self.filteredRecipes[row]

            // Reload the thumb image.
            let height = self.tableView.rowHeight-10

            cell?.imageLoadingRequestReceipt = recipe.loadImage(completionHandler: { image in
                guard let imgView = cell?.imageView else { return }
                // Animte the possible image change.
                UIView.transition(with: imgView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                    imgView.image = image?.af_imageAspectScaled(toFill: CGSize(width: height, height: height))
                })
                cell?.setNeedsLayout()
            })

            // Update the displayed text.
            if let name = recipeDetails["name"] as? String {
                cell?.textLabel?.text = name
                cell?.setNeedsDisplay()

                // We need to update the recipe name because otherwise the search update will not work.
                recipe.name = name
            }

            // If we are currently searching for a recipe, we might need to update the list.
            if !searchText.isEmpty {
                self.updateSearchResults()
            }
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
