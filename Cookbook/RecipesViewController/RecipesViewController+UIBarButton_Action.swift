//
//  RecipesViewController+BarButton.swift
//  Cookbook
//
//  Created by David Klopp on 14.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Bar Button Callbacks

extension RecipesViewController {

    #if !targetEnvironment(macCatalyst)
    /**
     Present the settings view controller on iOS
    */
    @objc func showPreferencesiOS(item: Any) {
        let settingsViewController = PreferencesViewControlleriOS()
        settingsViewController.beginSheetModal(self) { [weak settingsViewController] response in
            settingsViewController?.dismiss(animated: true)
            switch response {
            case .save:
                NotificationCenter.default.post(name: .reload, object: nil)
            case .cancel:
                break
            case .logout:
                NotificationCenter.default.post(name: .logout, object: nil)
            }
        }
    }
    #endif

    /// Create a new recipe.
    @objc func addRecipe(item: Any) {
        let storyBoard =  UIStoryboard(name: "Main", bundle: nil)
        let viewCon = storyBoard.instantiateViewController(withIdentifier: "RecipeDetailViewController")
        guard let newRecipeController = viewCon as? RecipeDetailViewController else { return }
        newRecipeController.includeParallaxHeaderView = false
        newRecipeController.isEditable = true

        // Setup the navigationBar items.
        newRecipeController.title = ""

        let saveButton = UIBarButtonItem.with(kind: .save)
        newRecipeController.navigationItem.rightBarButtonItem = saveButton
        saveButton.target = self
        saveButton.action = #selector(saveClicked)

        let cancelButton = UIBarButtonItem.with(kind: .cancel)
        newRecipeController.navigationItem.leftBarButtonItem = cancelButton
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)

        // Setup the navigationController.
        let navController = UINavigationController(rootViewController: newRecipeController)
        navController.modalPresentationStyle = .formSheet
        navController.navigationBar.isHidden = false

        #if targetEnvironment(macCatalyst)
        navController.navigationBar.barTintColor = self.view.tintColor
        navController.navigationBar.tintColor = .white
        #endif

        self.newRecipeController = newRecipeController
        self.present(navController, animated: true)
    }

    @objc private func cancelClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func saveClicked(_ sender: Any) {
        // TODO: Fix this function.
        // Update the recipeDetails from the ui values.
        /*self.newRecipeController?.updateRecipeDetailsFromUI()

        if let details = self.newRecipeController?.recipeDetails, let name = details["name"] as? String, !name.isEmpty {
            // Create a new recipe with the given data.
            Recipe.create(details, completionHandler: { recipeID in
                // Reload the sidebar.
                self.reloadRecipes({ recipes in
                    // Open the newly created recipe.
                    if let newIndexRow = recipes.firstIndex(where: { $0.recipeID == recipeID }) {
                        self.firstSelectedRow = newIndexRow
                    }
                    self.updateSearchResults(for: self.searchController)

                    // Dismiss the created popup.
                    self.dismiss(animated: true, completion: {
                        self.newRecipeController = nil
                    })
                })
            }, errorHandler: { error in
                print(error)
                // Unknown error while creating a recipe.
                ProgressHUD.showError(attachedTo: self.newRecipeController?.view,
                                  message: NSLocalizedString("ERROR_CREATE_RECIPE", comment: ""), animated: true)?
                    .hide(animated: true, afterDelay: kErrorHudDisplayDuration)
            })

        } else {
            // User forgot to enter a recipe name.
            ProgressHUD.showError(attachedTo: self.newRecipeController?.view,
                                  message: NSLocalizedString("ERROR_MISSING_NAME", comment: ""), animated: true)?
                .hide(animated: true, afterDelay: kErrorHudDisplayDuration)
        }*/
    }
}
