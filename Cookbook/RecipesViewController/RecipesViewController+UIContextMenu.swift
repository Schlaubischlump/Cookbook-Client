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
            let userActivity = NSUserActivity(activityType: ActivityType.main)
            userActivity.title = ActivityTitle.newWindow
            // We need to find the real indexPath for this row, not the one in the filtered list.
            let recipeID = self.filteredRecipes[indexPath.row].recipeID
            let trueIndexPath = self.recipes.firstIndex(where: { $0.recipeID == recipeID } )
            userActivity.userInfo = ["row": trueIndexPath ?? 0]
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
            if indexPath != self.tableView.indexPathForSelectedRow {
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
                self.performSegue(withIdentifier: "showDetail", sender: nil)
            }
            let splitViewController = self.splitViewController as? SplitViewController
            var item: Any?

            #if targetEnvironment(macCatalyst)
            let toolbarItems = self.view.window?.windowScene?.titlebar?.toolbar?.items
            item = toolbarItems?.filter { $0.itemIdentifier == UIBarButtonItem.Kind.edit.identifier }.first

            #endif
            // Wait 0.5 seconds until our viewController is added to the view hierachy. Otherwise the toolbar buttons
            // will not be toggled. This is caused by the fact, that the UIScene is only set after viewDidAppear.
            // The check in willEditRecipe in the SceneDelegate will therefore fail to identify the current window.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                splitViewController?.recipeDetailController?.editRecipe(item: item)
            }
        }
        return editRecipeAction
    }

    /// Action to delete the recipe at the given indexPath.
    private func deleteRecipeAction(forIndexPath indexPath: IndexPath) -> UIAction {
        let deleteRecipeAction = UIAction(title: NSLocalizedString("DELETE_RECIPE", comment: ""),
                                          image: UIImage(systemName: "trash")) { _ in
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
        var items: [UIAction] = []
        // Disable new window option on iPhones
        if UIDevice.current.userInterfaceIdiom != .phone {
            items.append(self.newWindowAction(forIndexPath: indexPath))
        }

        // Add universell actions.
        items.append(self.createRecipeAction(forIndexPath: indexPath))
        items.append(self.editRecipeAction(forIndexPath: indexPath))
        items.append(self.deleteRecipeAction(forIndexPath: indexPath))

        let actionProvider: ([UIMenuElement]) -> UIMenu? = { _ in
            return UIMenu(title: NSLocalizedString("ACTION", comment: ""), image: nil, identifier: nil, children: items)
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
    }
}
