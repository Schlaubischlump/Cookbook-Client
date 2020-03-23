//
//  RecipesViewController+UISearchController.swift
//  Cookbook
//
//  Created by David Klopp on 15.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension RecipesViewController: UISearchResultsUpdating {
    /// Helper function for easier access.
    func updateSearchResults() {
        self.updateSearchResults(for: self.searchController)
    }

    /// Update the search results when the searchField query changes.
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }

        // If an item is selected, make sure to keep the selection intact. This is for example important if you edit
        // a recipe while you are searching.
        let selectedRow = tableView.indexPathForSelectedRow?.row
        let keepSelection = selectedRow != nil
        let recipeID: Int? = keepSelection ? self.filteredRecipes[selectedRow!].recipeID : nil

        // Update the search result.
        if searchText.isEmpty {
            self.filteredRecipes = self.recipes
        } else {
            self.filteredRecipes = self.recipes.filter { (recipe: Recipe) -> Bool in
                return recipe.name.lowercased().contains(searchText.lowercased())
            }
        }

        // When we do not open a new window we need to calculate which row to open.
        if !self.isActivatedByNewWindowActivity {
            // Calculate the new index of the same recipe. If it does not exist (e.g. during a search) we do not want to
            // select any cell. That means we need to set `firstSelectedRow` to nil.
            self.firstSelectedRow = self.filteredRecipes.firstIndex(where: { $0.recipeID == recipeID })
            // In case that we deleted the recipe, we need to select the previous row.
            // Use max to prevent an index -1 error when deleting the first row.
            if recipeID != nil && !self.recipes.contains(where: { $0.recipeID == recipeID }) {
                self.firstSelectedRow = max((selectedRow ?? 0) - 1, 0)
            } else if searchText.isEmpty {
                // If the search result was cleared, we need to find the index of the currently opened recipe inside the
                // detailed view. The tableView selection will be nil, although a recipe is open.
                let splitViewController = self.splitViewController as? SplitViewController
                let recipe = splitViewController?.recipeDetailController?.recipe
                self.firstSelectedRow = self.recipes.firstIndex(where: { $0.recipeID == recipe?.recipeID }) ?? 0
            }
        }

        self.tableView.reloadData()
    }
}
