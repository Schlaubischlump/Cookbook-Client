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
        let activity = NSUserActivity(activityType: ActivityType.default)
        if let splitViewController = self.window?.rootViewController as? SplitViewController,
           let recipeDetailController = splitViewController.recipeDetailController,
           let recipe = recipeDetailController.recipe {
                activity.title = ActivityTitle.newWindow
                activity.persistentIdentifier = UUID().uuidString
                activity.addUserInfoEntries(from: recipe.toDict())
        }
        return activity
    }

    // MARK: - Helper
    /**
     Restore the scene state when a new window opens.
     */
    func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
        guard activity.title == ActivityTitle.newWindow else { return false }

        guard let info = activity.userInfo as? [String: Any],
              let recipe = Recipe.from(dict: info),
              let splitViewController = window?.rootViewController as? SplitViewController else { return false }

        let recipeDetailViewController = splitViewController.recipeDetailController
        recipeDetailViewController?.recipe = recipe

        // Configure the navigation and toolbar depending on the platform.
        #if targetEnvironment(macCatalyst)
        recipeDetailViewController?.navigationController?.isNavigationBarHidden = true
        #else
        recipeDetailViewController?.setupNavigationAndToolbar()
        #endif

        return true
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        // If we drag and drop a window or open one with the context menu, then the `configure` methods guarantees us
        // that we have a recipe. In this case we want to collapse to the detailViewController.
        let navController = secondaryViewController as? UINavigationController
        let recipeDetailViewController = navController?.topViewController as? RecipeDetailViewController
        return recipeDetailViewController?.recipe == nil
    }
}
