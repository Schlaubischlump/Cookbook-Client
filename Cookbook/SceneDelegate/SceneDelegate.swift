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
        splitViewController.delegate = self

        window.tintColor = UIColor(named: "cookbookGreen")

        #if targetEnvironment(macCatalyst)
        // Setup the mac toolbar and register all notifications to enable / disable the toolbar items.
        self.setupToolbar()
        self.registerNotifications()
        #else
        // Add the displayModeButton to the splitViewController to provide a fullscreen experience on iOS.
        let navItem = splitViewController.recipeDetailController?.navigationItem
        navItem?.leftBarButtonItem = splitViewController.displayModeButtonItem
        navItem?.leftItemsSupplementBackButton = true
        #endif

        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            if !self.configure(window: window, with: userActivity) {
                print("Failed to restore from \(userActivity)")
            }
        }
    }

    #if targetEnvironment(macCatalyst)
    func sceneDidDisconnect(_ scene: UIScene) {
        self.deregisterNotifications()
    }
    #endif

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        let activity = NSUserActivity(activityType: ActivityType.default)

        if let splitViewController = self.window?.rootViewController as? SplitViewController,
           let recipeDetailController = splitViewController.recipeDetailController,
           let recipe = recipeDetailController.recipe {
                activity.persistentIdentifier = UUID().uuidString
                activity.addUserInfoEntries(from: recipe.toDict())
        }
        return activity
    }

    // MARK: - Helper

    /**
     Restore the scene state when a new window opens.
     - Parameter window: the current UIWindow instance belonging to this scene
     - Parameter activity: the activity which should be restored
     - Return: true when the scene state can be restored, false otherwise
     */
    func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
        // Make sure that the activity has the right type and does contain the necessary recipe information.
        guard activity.activityType == ActivityType.default,
              let info = activity.userInfo as? [String: Any],
              let recipe = Recipe.from(dict: info),
              let splitViewController = window?.rootViewController as? SplitViewController else { return false }

        // Update the recipeDetailView with the correct recipe information.
        let recipeDetailViewController = splitViewController.recipeDetailController
        recipeDetailViewController?.recipe = recipe

        // Configure the recipeDetailViews UINavigationBar and UIToolbarBar depending on the platform.
        #if targetEnvironment(macCatalyst)
        recipeDetailViewController?.navigationController?.isNavigationBarHidden = true
        #else
        recipeDetailViewController?.setupNavigationAndToolbar()
        #endif

        return true
    }

    // MARK: - UISplitViewControllerDelegate

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
