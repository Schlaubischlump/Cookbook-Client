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

// MARK: - Notification handling
extension RecipesViewController {
    /// Callback when a reload a forced with a notification.
    @objc func requestReload(_ notification: Notification) {
        self.reloadRecipes()
    }

    /// Called after a successfull logout.
    @objc func didLogout(_ notification: Notification) {
        self.recipes = []
        self.filteredRecipes = []
        self.tableView.reloadData()
        self.showNextcloudLogin()
    }

    /// Called after a login attempt.
    @objc func didAttemptLogin(_ notification: Notification) {
        self.reloadRecipes()
    }

    /// Called when a recipe is deleted.
    @objc func didRemoveRecipe(_ notification: Notification) {
        guard let recipeID = notification.userInfo?["recipeID"] as? Int else { return }
        // Find the index of the recipe to delete
        if let index = self.recipes.firstIndex(where: { $0.recipeID == recipeID }) {
            self.recipes.remove(at: index)
            // use max to prevent an index -1 error when deleting the first row
            self.firstSelectedRow = max((self.tableView.indexPathForSelectedRow?.row ?? 0) - 1, 0)
            self.updateSearchResults()
        }
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

    /// Called when a new recipe was added.
    @objc func didAddRecipe(_ notification: Notification) {
        guard let recipeID = notification.userInfo?["recipeID"] as? Int else { return }
    }
}