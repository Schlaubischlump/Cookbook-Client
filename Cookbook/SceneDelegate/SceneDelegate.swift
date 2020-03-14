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
        guard let splitViewController = window.rootViewController as? UISplitViewController else { return }
        guard let navigationController = splitViewController.viewControllers.last as? UINavigationController else {
            return
        }
        guard let navItem = navigationController.topViewController?.navigationItem else { return }

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

        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            if !self.configure(window: window, with: userActivity) {
                print("Failed to restore from \(userActivity)")
            }
        }
    }

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
            let splitViewController = window?.rootViewController as? UISplitViewController,
            let navController = splitViewController.viewControllers.first as? UINavigationController,
            let recipesController = navController.topViewController as? RecipesViewController else { return false }

        // Select the user specified row.
        recipesController.firstSelectedRow = row
        recipesController.isActivatedByNewWindowActivity = true
        return true
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        guard let navController = secondaryViewController as? UINavigationController else { return false }
        guard let detailController = navController.topViewController as? RecipeDetailViewController else { return false}

        if detailController.detailItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will
            // be discarded.
            return true
        }
        return false
    }

    /*func splitViewController(_ svc: UISplitViewController,
                             willChangeTo displayMode: UISplitViewController.DisplayMode) {
        guard let navController = svc.viewControllers.last as? UINavigationController,
            let detailController = navController.topViewController as? RecipeDetailViewController else { return }

        if detailController.isViewLoaded {
            print("Yes is loaded")
            UIView.animate(withDuration: 0.5, animations: {
                // Force a relayout.
                detailController.updateContentSize()
            })
        }
    }*/
}
