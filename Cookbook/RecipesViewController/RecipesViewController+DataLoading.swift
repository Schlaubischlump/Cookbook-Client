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

    /**
     Reload all recipes from the server. If an error occurs we assume the user entered the wrong login credentials and
     display the login window.
     */
    func reloadRecipes(_ completionHandler: @escaping ([Recipe]) -> Void = { _ in },
                       errorHandler: @escaping (Error) -> Void = { _ in }) {
        // If we are currently showing the login view we want to attach all ProgressHUDs to this view.
        var attachedView: UIView?
        if let view = self.loginViewController?.view {
            attachedView = view
        } else if let view = self.splitViewController?.view {
            attachedView = view
        }

        NotificationCenter.default.post(name: .willLoadRecipes, object: nil)

        // Show a loading spinner.
        let hud = ProgressHUD.showSpinner(attachedTo: attachedView)
        Recipe.loadRecipes(completionHandler: { recipes in
            self.recipes = recipes
            self.filteredRecipes = recipes
            self.tableView.reloadData()

            hud?.hide(animated: true)

            // Save the login information for the next time and dismiss the login screen if it exists.
            try? loginCredentials.updateStoredInformation()
            // Dismiss the login view if it is currently visible.
            self.dismiss(animated: true, completion: {
                self.loginViewController = nil
                // Start to generate Notifications for progress HUDs.
                completionHandler(self.recipes)
                // Inform all observers about the new recipes.
                NotificationCenter.default.post(name: .didLoadRecipes, object: nil)
            })
        }, errorHandler: { error in
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

            errorHandler(error)
        })
    }
}
