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

extension RecipesViewController: ReloadableViewController {
    /**
     Reload the tableview.
     */
    func reloadDataFromCache() {
        self.updateSearchResults()
    }

    /**
     Reload all recipes from the server. If an error occurs we assume the user entered the wrong login credentials and
     display the login window.
     */
    func reloadDataFromServer() {
        // If we are currently showing the login view we want to attach all ProgressHUDs to this view.
        let attachedView = self.loginViewController?.view ?? self.splitViewController?.view

        NotificationCenter.default.post(name: .willLoadRecipes, object: self)

        // Show a loading spinner.
        let hud = ProgressHUD.showSpinner(attachedTo: attachedView)
        Recipe.loadRecipes(completionHandler: { recipes in
            self.recipes = recipes
            self.filteredRecipes = recipes
            self.updateSearchResults()

            hud?.hide(animated: true)

            // Save the login information for the next time and dismiss the login screen if it exists.
            try? loginCredentials.updateStoredInformation()

            // Inform all observers about the new recipes.
            NotificationCenter.default.post(name: .didLoadRecipes, object: self)

            // Dismiss the login view if it is currently visible.
            if self.loginViewController != nil {
                self.dismiss(animated: true, completion: {
                    self.loginViewController = nil
                })
            } else {
                NotificationCenter.default.post(name: .didLoadRecipes, object: self)
            }
        }, errorHandler: { _ in
            self.recipes = []
            self.filteredRecipes = []
            self.tableView.reloadData()

            // Hide the progress spinner.
            hud?.hide(animated: false)

            // If the reloading operation failed, we assume the user entered wrong credentials.
            // Show the login screen to let the user enter new credentials.
            if self.loginViewController == nil {
                self.showNextcloudLogin()
            } else {
                // Show an error message
                ProgressHUD.showError(attachedTo: self.loginViewController?.view,
                                      message: NSLocalizedString("INVALID_LOGIN", comment: ""),
                                      animated: true)?.hide(animated: true, afterDelay: kErrorHudDisplayDuration)
            }
        })
    }

    /**
     Reload the recipes either from the cache or the server
     */
    func reloadData(useCachedData: Bool=true) {
        if useCachedData {
            self.reloadDataFromCache()
        } else {
            self.reloadDataFromServer()
        }
    }
}
