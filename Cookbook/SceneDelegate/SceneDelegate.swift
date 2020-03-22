//
//  SceneDelegate.swift
//  Cookbook
//
//  Created by David Klopp on 22.12.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import UIKit

// MARK: - Scene Delegate

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let window = window else { return }
        guard let splitViewController = window.rootViewController as? SplitViewController else { return }
        guard let navItem = splitViewController.recipeDetailController?.navigationItem else { return }

        navItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        navItem.leftItemsSupplementBackButton = true
        splitViewController.delegate = self

        // Mac specific layout.
        #if targetEnvironment(macCatalyst)
        splitViewController.primaryBackgroundStyle = .sidebar

        // Hide the titlebar and add a toolbar
        guard let windowScene = (scene as? UIWindowScene) else { return }
        if let titlebar = windowScene.titlebar {
            let toolbar = NSToolbar(identifier: "toolbar")
            toolbar.delegate = self
            toolbar.allowsUserCustomization = true
            toolbar.displayMode = .iconOnly
            titlebar.autoHidesToolbarInFullScreen = true

            //titlebar.titleVisibility = .hidden
            titlebar.toolbar = toolbar
        }
        #else
        splitViewController.preferredDisplayMode = .allVisible
        splitViewController.view.backgroundColor = .lightGray
        #endif

        // Register notification center events for ProgressHUD.
        #if targetEnvironment(macCatalyst)
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(willLoadRecipes), name: .willLoadRecipes, object: nil)
        center.addObserver(self, selector: #selector(didLoadRecipes), name: .didLoadRecipes, object: nil)
        center.addObserver(self, selector: #selector(didLogout), name: .logout, object: nil)
        center.addObserver(self, selector: #selector(didLogin), name: .login, object: nil)
        center.addObserver(self, selector: #selector(willLoadRecipeDetails), name: .willLoadRecipeDetails, object: nil)
        center.addObserver(self, selector: #selector(didLoadRecipeDetails), name: .didLoadRecipeDetails, object: nil)
        center.addObserver(self, selector: #selector(willAddRecipe), name: .willAddRecipe, object: nil)
        center.addObserver(self, selector: #selector(didAddRecipe), name: .didAddRecipe, object: nil)
        center.addObserver(self, selector: #selector(willEditRecipe), name: .willEditRecipe, object: nil)
        center.addObserver(self, selector: #selector(didEditRecipe), name: .didEditRecipe, object: nil)
        center.addObserver(self, selector: #selector(didRemoveRecipe), name: .didRemoveRecipe, object: nil)
        #endif

        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            if !self.configure(window: window, with: userActivity) {
                print("Failed to restore from \(userActivity)")
            }
        }
    }

    #if targetEnvironment(macCatalyst)
    func sceneDidDisconnect(_ scene: UIScene) {
        // Stop listening for HUD changes.
        let center = NotificationCenter.default
        center.removeObserver(self, name: .willLoadRecipes, object: nil)
        center.removeObserver(self, name: .didLoadRecipes, object: nil)
        center.removeObserver(self, name: .logout, object: nil)
        center.removeObserver(self, name: .login, object: nil)
        center.removeObserver(self, name: .willLoadRecipeDetails, object: nil)
        center.removeObserver(self, name: .didLoadRecipeDetails, object: nil)
        center.removeObserver(self, name: .willEditRecipe, object: nil)
        center.removeObserver(self, name: .didEditRecipe, object: nil)
        center.removeObserver(self, name: .willAddRecipe, object: nil)
        center.removeObserver(self, name: .didAddRecipe, object: nil)
        center.removeObserver(self, name: .didRemoveRecipe, object: nil)
    }
    #endif

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }

    // MARK: - Helper
    /**
     Restore the scene state when a new window opens.
     */
    func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
        guard activity.title == ActivityTitle.newWindow else { return false }

        guard let row = activity.userInfo?["row"] as? Int,
            let splitViewController = window?.rootViewController as? SplitViewController else { return false }

        // Select the user specified row.
        splitViewController.recipesMasterController?.firstSelectedRow = row
        splitViewController.recipesMasterController?.isActivatedByNewWindowActivity = true
        return true
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {

        if (splitViewController as? SplitViewController)?.recipeDetailController?.recipe == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will
            // be discarded.
            return true
        }
        return false
    }
}
