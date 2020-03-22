//
//  RecipesViewController+BarButtonSetup.swift
//  Cookbook
//
//  Created by David Klopp on 19.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension RecipeDetailViewController {
    /**
     Setup the navigation and toolbar items on iOS. MacOS does not need this method, because it uses NSToolbarItems.
     */
    func setupNavigationAndToolbar() {
        // Setup the toolbar to add/edit/delte items.
        self.navigationController?.isToolbarHidden = false

        // Add toolbar items.
        let shareButton = UIBarButtonItem.with(kind: .share)
        shareButton.isEnabled = false
        shareButton.target = self
        shareButton.action = #selector(self.shareRecipe)

        let deleteButton = UIBarButtonItem.with(kind: .delete)
        deleteButton.isEnabled = false
        deleteButton.target = self
        deleteButton.action = #selector(self.deleteRecipe)

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        self.toolbarItems = [deleteButton, flexibleSpace, shareButton]

        // Add navigationbar items.
        let editButton = UIBarButtonItem.with(kind: .edit)
        editButton.isEnabled = false
        editButton.target = self
        editButton.action = #selector(self.editRecipe)
        self.navigationItem.rightBarButtonItem = editButton

        // Add a observers to disable / enable the UIBarButtonItems while loading the recipe.
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.disableNavigationAndToolbarItems),
                           name: .willLoadRecipeDetails, object: nil)
        center.addObserver(self, selector: #selector(self.enableNavigationAndToolbarItems),
                           name: .didLoadRecipeDetails, object: nil)
    }
}
