//
//  RecipesViewController+DataLoading.swift
//  Cookbook
//
//  Created by David Klopp on 18.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

extension RecipesViewController {

    /// If the login credentials are set load the data otherwise do nothing.
    func loadDataIfLoginCredentialsAreSet() {
        guard loginCredentials.informationIsSet() else { return }
        let hud = ProgressHUD.showSpinner(attachedTo: self.splitViewController?.view)
        self.reloadRecipes { [weak self] result in
            hud?.hide(animated: true)

            switch result {
            case .success:
                break
            case .failure:
                // Login information seems to be incorrect => Show login dialog
                self?.showNextcloudLogin()
                ProgressHUD.showError(attachedTo: self?.presentedViewController?.view,
                                      message: NSLocalizedString("ERROR_LOADING_RECIPES", comment: ""),
                                      animated: true)?
                            .hide(animated: true, afterDelay: kErrorHudDisplayDuration)
            }
        }
    }

    /**
     Reload all recipes from the server and optinally provide a success/failure handler.
     - Parameter completion: completion handler
     */
    func reloadRecipes(_ completion: @escaping ResultHandler = { _ in }) {
        Recipe.loadRecipes(completionHandler: { recipes in
            self.recipes = recipes
            self.filteredRecipes = recipes
            self.tableView.reloadData()
            // Reload did work.
            completion(Swift.Result.success(()))
        }, errorHandler: { err in
            self.recipes = []
            self.filteredRecipes = []
            self.tableView.reloadData()
            // Reload failed
            completion(Swift.Result.failure(err))
        })
    }

    // MARK: - Helper for add / edit / remove

    /// Reload all the visible thumb images.
    func reloadVisibleThumbImages() {
        let height = self.tableView.rowHeight-10
        // Only reload the images of all visible cells.
        for indexPath in self.tableView.indexPathsForVisibleRows ?? [] {
            guard let recipeCell = self.tableView.cellForRow(at: indexPath) as? RecipesTableViewCell else { return }

            // Load the possible new images asynchronous.
            let recipe = self.filteredRecipes[indexPath.row]
            recipeCell.imageLoadingRequestReceipt = recipe.loadImage(completionHandler: { image in
                guard let imgView = recipeCell.imageView else { return }
                // Animte the possible image change.
                UIView.transition(with: imgView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                    imgView.image = image?.af_imageAspectScaled(toFill: CGSize(width: height, height: height))
                    recipeCell.setNeedsLayout()
                })
            })
        }
    }

    func reloadVisibleTitles() {
        for indexPath in self.tableView.indexPathsForVisibleRows ?? [] {
            guard let recipeCell = self.tableView.cellForRow(at: indexPath) as? RecipesTableViewCell else { return }
            recipeCell.textLabel?.text = self.filteredRecipes[indexPath.row].name
            recipeCell.setNeedsDisplay()
        }
        // Update the currently displayed search results.
        self.updateSearchResults(for: self.searchController)
    }

    func removeRecipe(_ recipe: Recipe) {
        self.recipes.removeAll(where: { $0.recipeID == recipe.recipeID })
        self.updateSearchResults(for: self.searchController)
        self.tableView.reloadData()
    }
}
