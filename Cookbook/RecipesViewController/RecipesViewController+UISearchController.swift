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

        print("Update the search result.")

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
                print(recipe.name.lowercased())
                return recipe.name.lowercased().contains(searchText.lowercased())
            }
        }

        // Calculate the new index of the same recipe.
        self.firstSelectedRow = self.filteredRecipes.firstIndex(where: { $0.recipeID == recipeID })

        self.tableView.reloadData()
    }
}
