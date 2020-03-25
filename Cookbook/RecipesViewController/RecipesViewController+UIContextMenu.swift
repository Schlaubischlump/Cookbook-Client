//
//  RecipesViewController+ContextMenu.swift
//  Cookbook
//
//  Created by David Klopp on 14.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension RecipesViewController {
    /// Action to open the selected recipe in a new window.
    private func newWindowAction(forIndexPath indexPath: IndexPath) -> UIAction {
        let newWindowAction = UIAction(title: NSLocalizedString("OPEN_IN_NEW_WINDOW", comment: ""),
                                       image: UIImage(systemName: "uiwindow.split.2x1")) { _ in
            // Open a new default window.
            let userActivity = NSUserActivity(activityType: ActivityType.default)
            userActivity.userInfo = self.filteredRecipes[indexPath.row].toDict()
            UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil)
        }
        return newWindowAction
    }

    /// Action to create a new recipe.
    private func createRecipeAction(forIndexPath indexPath: IndexPath) -> UIAction {
        let createRecipeAction = UIAction(title: NSLocalizedString("CREATE_NEW_RECIPE", comment: ""),
                                          image: UIImage(systemName: "plus.square")) { _ in
            self.addRecipe(item: nil)
        }
        return createRecipeAction
    }

    /// Action to edit the recipe at the given indexPath.
    private func editRecipeAction(forIndexPath indexPath: IndexPath) -> UIAction {
        let editRecipeAction = UIAction(title: NSLocalizedString("EDIT_RECIPE", comment: ""),
                                  image: UIImage(systemName: "square.and.pencil")) { _ in
            // Setup the detail view to open in edit mode.
            let splitViewController = self.splitViewController as? SplitViewController
            let recipesViewController = splitViewController?.recipesMasterController
            let openRecipe = recipesViewController?.filteredRecipes[indexPath.row]
            // Check if the recipe is already open and start the edit mode if this is the case.
            if let recipeDetailViewController = splitViewController?.recipeDetailController,
               recipeDetailViewController.recipe?.recipeID == openRecipe?.recipeID {
                recipeDetailViewController.editRecipe(item: nil)
            } else {
                recipesViewController?.openNextRecipeDetailViewInEditMode = true

                // Open the detail view.
                if indexPath != self.tableView.indexPathForSelectedRow {
                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
                    self.performSegue(withIdentifier: "showDetail", sender: nil)
                }
            }

        }
        return editRecipeAction
    }

    /// Action to delete the recipe at the given indexPath.
    private func deleteRecipeAction(forIndexPath indexPath: IndexPath) -> UIAction {
        let deleteRecipeAction = UIAction(title: NSLocalizedString("DELETE_RECIPE", comment: ""),
                                          image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            let alert = UIAlertController(title: NSLocalizedString("CONFIRM_DELETE_TITLE", comment: ""),
                                          message: NSLocalizedString("CONFIRM_DELETE_MESSAGE", comment: ""),
                                          preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { _ in
                let center = NotificationCenter.default
                let recipe = self.filteredRecipes[indexPath.row]
                // Delete the recipe from the server.
                recipe.delete({
                    // Inform all listeners, that the recipe was deleted.
                    center.post(name: .didRemoveRecipe, object: self, userInfo: ["recipeID": recipe.recipeID])
                }, errorHandler: { _ in
                    // Inform all listeners, that the recipe deletion failed.
                    center.post(name: .didRemoveRecipe, object: self, userInfo: nil)
                    // Inform the user that something went wrong.
                    ProgressHUD.showError(attachedTo: self.view,
                                          message: NSLocalizedString("ERROR_DELETING", comment: ""),
                                          animated: true)?.hide(animated: true, afterDelay: kErrorHudDisplayDuration)
                })
            }))
            let action = UIAlertAction(title: NSLocalizedString("CANCEL", comment: ""), style: .cancel, handler: nil)
            alert.addAction(action)

            self.present(alert, animated: true)
        }
        return deleteRecipeAction
    }

    /**
     Show different menu options when the user right clicks / force touches on a recipe in the list.
     */
    public override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
                                   point: CGPoint) -> UIContextMenuConfiguration? {
        // Disable new window option on iPhones
        var items: [UIMenuElement] = []
        if UIDevice.current.userInterfaceIdiom != .phone {
            items.append(self.newWindowAction(forIndexPath: indexPath))
        }

        let createRecipeAction = self.createRecipeAction(forIndexPath: indexPath)
        let editRecipeAction = self.editRecipeAction(forIndexPath: indexPath)
        let deleteRecipeAction = self.deleteRecipeAction(forIndexPath: indexPath)

        // Add actions available on all platforms.
        #if targetEnvironment(macCatalyst)
        // Add a little separator between the items on macOS.
        let actionMenu = UIMenu(title: "", options: .displayInline, children: [createRecipeAction, editRecipeAction])
        let deleteMenu = UIMenu(title: "", options: .displayInline, children: [deleteRecipeAction])
        items += [actionMenu, deleteMenu]
        #else
        items += [createRecipeAction, editRecipeAction, deleteRecipeAction]
        #endif

        let actionProvider: UIContextMenuActionProvider = { _ in
            return UIMenu(title: "", image: nil, identifier: nil, children: items)
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
    }
}
