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
    override var displayModeButtonItem: UIBarButtonItem {
        // Catalyst does not implement splitViewController.displayModeButtonItem yet.
        #if targetEnvironment(macCatalyst)
        let configuration = UIImage.SymbolConfiguration(weight: .light)
        let tintColor = UIColor(displayP3Red: 86/255.0, green: 86/255.0, blue: 86/255.0, alpha: 1.0)
        var sidebarImage = UIImage(systemName: "sidebar.left", withConfiguration: configuration)
        sidebarImage = sidebarImage?.withTintColor(tintColor)
        sidebarImage = sidebarImage?.af_imageAspectScaled(toFit: CGSize(width: 44, height: 44))
        return UIBarButtonItem(image: sidebarImage, style: .plain, target: self, action: #selector(self.toggleSidebar))
        #else
        return super.displayModeButtonItem
        #endif
    }

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
