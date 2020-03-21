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
     Extend the scrollView contentInset bottom when the keyboard is visible.
     */
    @objc func keyboardDidShow(_ notification: Notification) {
        let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        self.scrollView.contentInset.bottom = keyboardRect?.height ?? 0
    }

    /**
     Remove the additional scrollView contentInset bottom when the keyboard is hidden.
     */
    @objc func keyboardDidHide(_ notification: Notification) {
        self.scrollView.contentInset.bottom = 0
    }

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
     Called when a recipe was successfully updated.
     */
    @objc func didEditRecipe(_ notification: Notification) {
        if let recipeID = notification.userInfo?["recipeID"] as? Int,
           let newRecipeDetails = notification.userInfo?["details"] as? [String: Any] {

            // If the currently displayed recipe belong to this recipe change the dispalyed information.
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
                // Start editing the recipeDetail view.
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
}
