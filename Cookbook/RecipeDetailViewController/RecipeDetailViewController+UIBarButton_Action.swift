//
//  RecipeDetailViewController+BarButtonAction.swift
//  Cookbook
//
//  Created by David Klopp on 17.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

extension RecipeDetailViewController {
    /// Show the share sheet for a recipe.
    @objc func shareRecipe(item: Any?) {
        if let data = self.pdfRepresentation() {
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Recipe.pdf")
            try? data.write(to: url)
            let acViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            // item as? UIBarButtonItem is None for all platforms other then iPad OS
            acViewController.popoverPresentationController?.barButtonItem = item as? UIBarButtonItem
            self.present(acViewController, animated: true)
        }
    }

    /// Edit the current recipe.
    @objc func editRecipe(item: Any?) {
        // Just update the UI to represent the edit state.
        if !self.isEditable {
            UIView.animate(withDuration: 0.25, animations: {
                self.isEditable = true
            })

            // Update the toolbar items on iOS.
            #if !targetEnvironment(macCatalyst)
            let editButton = UIBarButtonItem.with(kind: .done, target: self, action: #selector(self.editRecipe))
            self.navigationItem.rightBarButtonItem = editButton
            // Disable the share button.
            self.toolbarItems?.last?.isEnabled = false
            #endif

            NotificationCenter.default.post(name: .willEditRecipe, object: self, userInfo: nil)
            return
        }

        // Update the information on the server.
        let hud = ProgressHUD.showSpinner(attachedTo: self.view, animated: true)
        guard var details = self.proposedRecipeDetails else { return }

        // Convert the time values to an array to before sending them to the server.
        for timeKey in ["prepTime", "cookTime", "totalTime"] {
            if let time = details[timeKey] as? String, let comp = try? DateComponents.from(iso8601String: time) {
                details[timeKey] = [comp.hour ?? 0, comp.minute ?? 0]
            }
        }

        self.recipe?.update(details, completionHandler: {
            // Inform all listeners, that the recipe was changed.
            var userInfo: [String: Any] = [:]
            if let proposedDetails = self.proposedRecipeDetails {
                userInfo["details"] = proposedDetails
            }
            if let recipeID = self.recipe?.recipeID {
                userInfo["recipeID"] = recipeID
            }

            // Update the toolbar items on iOS.
            #if !targetEnvironment(macCatalyst)
            let editButton = UIBarButtonItem.with(kind: .edit, target: self, action: #selector(self.editRecipe))
            self.navigationItem.rightBarButtonItem = editButton
            // Enable the share button.
            self.toolbarItems?.last?.isEnabled = true
            #endif

            NotificationCenter.default.post(name: .didEditRecipe, object: self, userInfo: userInfo)
            hud?.hide(animated: true)
        }, errorHandler: { _ in
            NotificationCenter.default.post(name: .didEditRecipe, object: self, userInfo: nil)
            // Inform the user that the update operation did not work.
            hud?.hide(animated: false)
            ProgressHUD.showError(attachedTo: self.view,
                                  message: NSLocalizedString("ERROR_UPDATING", comment: ""),
                                  animated: true)?.hide(animated: true, afterDelay: kErrorHudDisplayDuration)
        })
    }

    /// Delete the current recipe.
    @objc func deleteRecipe(item: Any?) {
        guard let recipe = self.recipe else { return }

        // Let the user confirm the deletion.
        let alert = UIAlertController(title: NSLocalizedString("CONFIRM_DELETE_TITLE", comment: ""),
                                      message: NSLocalizedString("CONFIRM_DELETE_MESSAGE", comment: ""),
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { _ in
            let center = NotificationCenter.default
            // Delete the recipe from the server.
            recipe.delete({
                // Inform all listeners, that the recipe was deleted.
                center.post(name: .didRemoveRecipe, object: self, userInfo: ["recipeID": recipe.recipeID])
            }, errorHandler: { _ in
                // Inform all listeners, that the recipe deletion failed.
                center.post(name: .didRemoveRecipe, object: self, userInfo: nil)
                // Inform the user that something went wrong.
                ProgressHUD.showError(attachedTo: self.view, message: NSLocalizedString("ERROR_DELETING", comment: ""),
                                      animated: true)?.hide(animated: true, afterDelay: kErrorHudDisplayDuration)
            })
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }
}
