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
    @objc func shareRecipe(item: Any) {
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
    @objc func editRecipe(item: Any) {
        let edit = !self.isEditable

        /**
         Toggle between the edit and done button.
        */
        func toggleEditDoneButton() {
            #if targetEnvironment(macCatalyst)
            let toolbarItem = item as? NSToolbarItem
            toolbarItem?.image = .toolbarImage(edit ? kDoneToolbarImage : kEditToolbarImage)
            #else
            let editButton = UIBarButtonItem.with(kind: edit ? .done : .edit, target: self,
                                                  action: #selector(self.editRecipe))
            self.navigationItem.rightBarButtonItem = editButton
            #endif
        }

        // Just update the UI to represent the edit state.
        guard !edit else {
            toggleEditDoneButton()

            UIView.animate(withDuration: 0.25, animations: {
                self.isEditable = true
            })
            return
        }

        NotificationCenter.default.post(name: .willEditRecipe, object: self, userInfo: nil)
        // Update the information on the server.
        let hud = ProgressHUD.showSpinner(attachedTo: self.view, animated: true)
        self.recipe?.update(self.proposedRecipeDetails, completionHandler: {
            toggleEditDoneButton()
            // Inform all listeners, that the recipe was changed.
            var userInfo: [String: Any] = ["details": self.proposedRecipeDetails]
            if let recipeID = self.recipe?.recipeID {
                userInfo["recipeID"] = recipeID
            }
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
    @objc func deleteRecipe(item: Any) {
        guard let recipe = self.recipe else { return }

        // Let the user confirm the deletion.
        let alert = UIAlertController(title: NSLocalizedString("CONFIRM_DELETE_TITLE", comment: ""),
                                      message: NSLocalizedString("CONFIRM_DELETE_MESSAGE", comment: ""),
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { _ in
            // Delete the recipe from the server.
            recipe.delete({
                // Inform all listeners, that the recipe was deleted.
                let center = NotificationCenter.default
                center.post(name: .didRemoveRecipe, object: nil, userInfo: ["recipeID": recipe.recipeID])
            }, errorHandler: { _ in
                // Inform the user that something went wrong.
                ProgressHUD.showError(attachedTo: self.view, message: NSLocalizedString("ERROR_DELETING", comment: ""),
                                      animated: true)?.hide(animated: true, afterDelay: kErrorHudDisplayDuration)
            })
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }
}
