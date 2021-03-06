//
//  RecipeDetailViewController+DataLoading.swift
//  Cookbook
//
//  Created by David Klopp on 18.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension RecipeDetailViewController: ReloadableViewController {
    /// Remove all recipe information from the UI.
    private func resetData() {
        self.recipeDetails = [:]

        self.title = ""
        self.descriptionList?.title = ""
        self.parallaxHeaderImageView?.image = #imageLiteral(resourceName: "placeholder")
        self.descriptionList?.data = []
        self.toolsList?.data = []
        self.ingredientsList?.data = []
        self.instructionsList?.data = []

        self.updateContentSize()
    }

    /// Reload all data from the currently stored recipe details.
    func reloadDataFromCache() {
        guard !self.recipeDetails.isEmpty else { return }

        self.title = recipe?.name ?? ""
        self.descriptionList?.title = recipe?.name ?? ""

        let (descriptionKeys, descriptionData) = Recipe.parseDescriptionValuesFor(recipeDetails: self.recipeDetails)
        self.descriptionList?.enumerationStyle = .string(descriptionKeys)
        self.descriptionList?.data = descriptionData

        self.toolsList?.enumerationStyle = .bullet()
        self.toolsList?.data = self.recipeDetails["tool"] as? [String] ?? []

        self.ingredientsList?.enumerationStyle = .bullet()
        self.ingredientsList?.data = self.recipeDetails["recipeIngredient"]  as? [String] ?? []

        self.instructionsList?.enumerationStyle = .number
        self.instructionsList?.data = self.recipeDetails["recipeInstructions"]  as? [String] ?? []

        self.updateContentSize()
    }

    /// Load the new recipe details from the server and apply the new data.
    func reloadDataFromServer() {
        guard let recipe = self.recipe else { return }

        let center = NotificationCenter.default
        center.post(name: .willLoadRecipeDetails, object: self)

        self.title = recipe.name
        self.descriptionList?.title = recipe.name

        // Load the recipe details.
        let group = DispatchGroup()

        group.enter()
        recipe.loadRecipeDetails(completionHandler: { [weak self] prop in
            // v0.6 Migration fix. Check if we can restore the original time values.
            var details = prop
            for timeKey in ["prepTime", "cookTime", "totalTime"] where "PT0H0M" == prop?[timeKey] as? String {
                if let newTime = prop?["\(timeKey)_test"] as? String {
                        details?[timeKey] = newTime
                }
            }

            self?.recipeDetails = details ?? [:]
            self?.reloadDataFromCache()
            group.leave()
        }, errorHandler: { [weak self] _ in
            // Show loading recipe details error.
            group.leave()
            ProgressHUD.showError(attachedTo: self?.view,
                                  message: NSLocalizedString("ERROR_LOADING_RECIPE_DETAILS", comment: ""),
                                  animated: true)?.hide(animated: true, afterDelay: kErrorHudDisplayDuration)
        })

        // Load the actual image.
        group.enter()
        recipe.loadImage(completionHandler: { [weak self] image in
            self?.parallaxHeaderImageView?.image = image
            group.leave()
        }, thumb: false)

        // When all recipe details are loaded.
        group.notify(queue: .main) {
            center.post(name: .didLoadRecipeDetails, object: self)
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
