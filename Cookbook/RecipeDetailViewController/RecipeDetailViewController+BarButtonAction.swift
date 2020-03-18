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
        UIView.animate(withDuration: 0.25, animations: {
            self.isEditable = edit
        })

        #if targetEnvironment(macCatalyst)
        let toolbarItem = item as? NSToolbarItem
        toolbarItem?.image = .toolbarImage(edit ? kDoneToolbarImage : kEditToolbarImage)
        #else
        // Toggle the edit button and the done button.
        var editItem: UIBarButtonItem?
        if edit {
            editItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        } else {
            editItem = BarButtonItem.with(type: .edit)
        }
        editItem?.target = self
        editItem?.action = #selector(self.editRecipe)

        let items = (self.toolbarItems?.dropLast() ?? []) + [editItem!]
        self.setToolbarItems(items, animated: true)

        #endif
    }

    /// Delete the current recipe.
    @objc func deleteRecipe(item: Any) {
        guard let recipe = self.recipe else { return }

        recipe.delete({
            self.dismiss(animated: true, completion: nil)
            let masterController = (self.splitViewController as? SplitViewController)?.recipesMasterController
            masterController?.removeRecipe(recipe)
        }, errorHandler: { _ in
            ProgressHUD.showError(attachedTo: self.view, message: NSLocalizedString("ERROR_DELETING", comment: ""),
                                  animated: true)?.hide(animated: true, afterDelay: kErrorHudDisplayDuration)
        })
    }
}
