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
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }

        if searchText.isEmpty {
            self.filteredRecipes = self.recipes
        } else {
            self.filteredRecipes = self.recipes.filter { (recipe: Recipe) -> Bool in
                return recipe.name.lowercased().contains(searchText.lowercased())
            }
        }

        self.tableView.reloadData()
    }
}
