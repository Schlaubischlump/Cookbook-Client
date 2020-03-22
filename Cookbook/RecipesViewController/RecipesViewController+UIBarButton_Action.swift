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
                NotificationCenter.default.post(name: .reload, object: self)
            case .cancel:
                break
            case .logout:
                NotificationCenter.default.post(name: .logout, object: self)
            }
        }
    }
    #endif

    // MARK: - Create a new recipe.
    @objc func addRecipe(item: Any) {
        let storyBoard =  UIStoryboard(name: "Main", bundle: nil)
        let viewCon = storyBoard.instantiateViewController(withIdentifier: "RecipeDetailViewController")
        guard let newRecipeController = viewCon as? RecipeDetailViewController else { return }
        newRecipeController.includeParallaxHeaderView = false
        newRecipeController.isEditable = true

        // Setup the navigationBar items.
        newRecipeController.title = NSLocalizedString("NEW_RECIPE", comment: "")

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
        navController.navigationBar.barTintColor = .white
        //navController.navigationBar.tintColor = .white
        #endif

        NotificationCenter.default.post(name: .willAddRecipe, object: self)

        self.newRecipeController = newRecipeController
        self.present(navController, animated: true)
    }

    @objc private func cancelClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: .didAddRecipe, object: self, userInfo: nil)
    }

    @objc private func saveClicked(_ sender: Any) {
        // Read the user entered recip details.
        guard let details = self.newRecipeController?.proposedRecipeDetails else { return }
        // The user must at least enter a recipe name.
        if let name = details["name"] as? String, !name.isEmpty {
            // We can not create a recipe with the same name. (FIXME: Cookbook v.0.5.7 only)
            guard !self.recipes.contains(where: { $0.name == name }) else {
                ProgressHUD.showError(attachedTo: self.newRecipeController?.view,
                                      message: NSLocalizedString("ERROR_RECIPE_EXISTS", comment: ""), animated: true)?
                    .hide(animated: true, afterDelay: kErrorHudDisplayDuration)
                return
            }

            // Create a new recipe with the given data.
            let hud = ProgressHUD.showSpinner(attachedTo: self.newRecipeController?.view, animated: true)
            Recipe.create(details, completionHandler: { recipeID in
                hud?.hide(animated: true)
                // Inform all listener about the change.
                let userInfo: [String: Any] = ["recipeID": recipeID, "details": details]
                NotificationCenter.default.post(name: .didAddRecipe, object: self, userInfo: userInfo)
            }, errorHandler: { _ in
                hud?.hide(animated: false)
                // Inform all listeners that the oparation was canceled by sending the didAddRecipe message with
                // an empty userInfo dictionary.
                NotificationCenter.default.post(name: .didAddRecipe, object: self, userInfo: nil)
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
        }
    }
}
