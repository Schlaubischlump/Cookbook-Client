//
//  RecipesViewController+BarButton.swift
//  Cookbook
//
//  Created by David Klopp on 14.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Bar Button Callbacks

extension RecipesViewController {

    /// Present the settings view controller on iOS
    @objc func showPreferencesiOS(item: Any) {
        #if !targetEnvironment(macCatalyst)
        let settingsViewController = PreferencesViewControlleriOS()
        settingsViewController.beginSheetModal(self) { [weak settingsViewController] response in
            settingsViewController?.dismiss(animated: true)
            switch response {
            case .save:
                NotificationCenter.default.post(name: .reload, object: nil)
            case .cancel:
                break
            case .logout:
                NotificationCenter.default.post(name: .logout, object: nil)
            }
        }
        #endif
    }

    /// Create a new recipe.
    @objc func addRecipe(item: Any) {
        // TODO: Add recipe
    }
}
