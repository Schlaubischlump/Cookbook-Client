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

    // MARK: - Init
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Catalyst Helper
    @objc func toggleSidebar(item: Any) {
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
