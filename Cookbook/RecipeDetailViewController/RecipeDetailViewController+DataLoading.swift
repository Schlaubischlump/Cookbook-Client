//
//  RecipeDetailViewController+DataLoading.swift
//  Cookbook
//
//  Created by David Klopp on 18.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension RecipeDetailViewController {
    /// Remove all recipe information from the UI.
    private func resetData() {
        self.title = ""
        self.descriptionList?.title = ""
        self.parallaxHeaderImageView.image = #imageLiteral(resourceName: "placeholder")
        self.descriptionList.data = []
        self.toolsList.data = []
        self.ingredientsList.data = []
        self.instructionsList.data = []

        self.updateContentSize()
    }

    /// Reload all data from the currently stored recipe details.
    private func reloadDataFromCache() {
        guard !self.recipeDetails.isEmpty else { return }

        self.descriptionList?.title = recipe?.name

        let (descriptionKeys, descriptionData) = Recipe.parseDescriptionValuesFor(jsonArray: self.recipeDetails)
        self.descriptionList.enumerationStyle = .string(descriptionKeys)
        self.descriptionList.data = descriptionData

        self.toolsList.enumerationStyle = .bullet()
        self.toolsList.data = self.recipeDetails["tool"] as? [String] ?? []

        self.ingredientsList.enumerationStyle = .bullet()
        self.ingredientsList.data = self.recipeDetails["recipeIngredient"]  as? [String] ?? []

        self.instructionsList.enumerationStyle = .number
        self.instructionsList.data = self.recipeDetails["recipeInstructions"]  as? [String] ?? []

        self.updateContentSize()
    }

    /// Load the new recipe details from the server and apply the new data.
    private func reloadDataFromServer() {
        guard let recipe = self.recipe else { return }

        let center = NotificationCenter.default
        center.post(name: .willLoadRecipeDetails, object: nil)

        self.title = recipe.name
        self.descriptionList?.title = recipe.name

        // Load the recipe details.
        let group = DispatchGroup()

        group.enter()
        recipe.loadRecipeDetails(completionHandler: { prop in
            self.recipeDetails = prop!
            self.reloadDataFromCache()
            group.leave()
        }, errorHandler: { _ in
            // Show loading recipe details error.
            group.leave()
            ProgressHUD.showError(attachedTo: self.view,
                                  message: NSLocalizedString("ERROR_LOADING_RECIPE_DETAILS", comment: ""),
                                  animated: true)?.hide(animated: true, afterDelay: kErrorHudDisplayDuration)
        })

        // Load the actual image.
        group.enter()
        recipe.loadImage(completionHandler: {image in
            self.parallaxHeaderImageView.image = image
            group.leave()
        }, thumb: false)

        // When all recipe details are loaded.
        group.notify(queue: .main) {
            center.post(name: .didLoadRecipeDetails, object: nil)
        }
    }

    /**
     Reload the data either from the server or from the current cache.
     */
    @objc public func reloadData(useCachedData: Bool = true) {
        if self.recipe != nil {
            if useCachedData {
                self.reloadDataFromCache()
            } else {
                self.reloadDataFromServer()
            }
        } else {
            self.resetData()
        }
    }

}
