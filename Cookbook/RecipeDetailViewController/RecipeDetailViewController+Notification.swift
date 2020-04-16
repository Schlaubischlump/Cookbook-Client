//
//  RecipeDetailViewController+Notification.swift
//  Cookbook
//
//  Created by David Klopp on 19.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension RecipeDetailViewController {
    #if !targetEnvironment(macCatalyst)
    /**
     Disable all navigation and toolbar items.
    */
    @objc func disableNavigationAndToolbarItems(_ notification: Notification) {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.toolbarItems?.forEach { $0.isEnabled = false }
    }

    /**
     Enable all navigation and toolbar items.
    */
    @objc func enableNavigationAndToolbarItems(_ notification: Notification) {
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.navigationItem.rightBarButtonItem?.tintColor = self.view.tintColor
        self.toolbarItems?.forEach { $0.isEnabled = true }
    }
    #endif

    /**
     Called after the recipe details finished loading. Make sure to resize the UI to display all cells.
     */
    @objc func didLoadRecipeDetails(_ notification: Notification) {
        guard self == notification.object as? RecipeDetailViewController else { return }

        self.descriptionList?.reloadData()
        self.toolsList?.reloadData()
        self.ingredientsList?.reloadData()
        self.instructionsList?.reloadData()

        self.updateContentSize()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()

        // Toggle edit mode if we are forced to open in edit mode.
        if self.startEditModeOnViewDidAppear {
            self.editRecipe(item: nil)
        }
    }

    /**
     Called when a recipe was successfully updated.
     */
    @objc func didEditRecipe(_ notification: Notification) {
        if let recipeID = notification.userInfo?["recipeID"] as? Int,
           let newRecipeDetails = notification.userInfo?["details"] as? [String: Any] {

            // If the currently displayed recipe is the same as the edited recipe change the dispalyed information.
            guard recipeID == self.recipe?.recipeID else { return }

            // Update the displayed name.
            if let name = newRecipeDetails["name"] as? String {
                self.recipe?.name = name
                self.title = name
                self.descriptionList?.title = name
            }

            // Update the recipeDetails.
            self.recipeDetails = newRecipeDetails

            // Reload the data if we are not the view which edited this recipe.
            if self != notification.object as? RecipeDetailViewController {
                self.reloadData(useCachedData: true)
                // We need to reapply the isEditable flag, to show all informations in the description list.
                if self.isEditable {
                    self.isEditable = true
                }
            } else {
                // Stop editing the recipeDetail view if we are the active view.
                UIView.animate(withDuration: 0.25, animations: {
                    self.isEditable = false
                })
            }

            // Update the full size parallaxHeader image view.
            self.recipe?.loadImage(completionHandler: {[weak self] image in
                guard let view = self?.parallaxHeaderImageView else { return }
                UIView.transition(with: view, duration: 0.25, options: .transitionCrossDissolve, animations: {
                    view.image = image
                })
            }, thumb: false)
        }
    }

    /**
     Called when a recipe was deleted.
     */
    @objc func didRemoveRecipe(_ notification: Notification) {
        if let recipeID = notification.userInfo?["recipeID"] as? Int {
            // If this recipe is the current recipe.
            guard recipeID == self.recipe?.recipeID else { return }
            // Clear this view. This is important e.g when we delete the last recipe in the filteredList.
            self.recipe = nil
            self.reloadData()
            // If the master controller is hidden (size class compact) then we need to dismiss the detail controller.
            self.navigationController?.navigationController?.popToRootViewController(animated: true)
        }
    }
}
