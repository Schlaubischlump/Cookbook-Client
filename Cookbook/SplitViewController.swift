//
//  SplitViewController.swift
//  Cookbook
//
//  Created by David Klopp on 14.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

class SplitViewController: UISplitViewController {
    // MARK: - Properties
    public var recipeDetailController: RecipeDetailViewController? {
        return (self.viewControllers.last as? UINavigationController)?.topViewController as? RecipeDetailViewController
    }

    public var recipesMasterController: RecipesViewController? {
        return (self.viewControllers.first as? UINavigationController)?.topViewController as? RecipesViewController
    }

    // MARK: - View handling

    override func viewDidLoad() {
        super.viewDidLoad()

        #if targetEnvironment(macCatalyst)
        self.primaryBackgroundStyle = .sidebar
        let sidebarWidth: CGFloat = 300
        self.maximumPrimaryColumnWidth = sidebarWidth
        self.minimumPrimaryColumnWidth = sidebarWidth
        #else
        self.preferredDisplayMode = .allVisible
        self.view.backgroundColor = .lightGray
        #endif
    }

    #if targetEnvironment(macCatalyst)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The detailed View inside the splitViewController should never display a navigationBar on macOS.
        // This prevents the navigationBar on the initial startup, before a recipe is loaded.
        self.recipeDetailController?.navigationController?.navigationBar.isHidden = true
    }
    #endif

    // MARK: - Catalyst Helper
    @objc func toggleSidebar(item: Any?=nil) {
        // Make sure to make the master view controller the new fist responder.
        self.recipesMasterController?.view.becomeFirstResponder()

        // Toggle the sidebar button.
        UIView.animate(withDuration: 0.25, animations: {
            if self.preferredDisplayMode == .primaryHidden {
                self.preferredDisplayMode = .allVisible
            } else {
                self.preferredDisplayMode = .primaryHidden
            }

            // Force a relayout of the detailView
            self.recipeDetailController?.updateContentSize()
        })
    }
}
