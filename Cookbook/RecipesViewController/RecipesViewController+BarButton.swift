//
//  RecipesViewController+BarButton.swift
//  Cookbook
//
//  Created by David Klopp on 14.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

// MARK: - UIBarButton
/**
 Enum to represent the different kind of UIBarButtonItems.
 */
enum BarButtonType: String {
    case share = "SHARE"
    case settings = "SETTINGS" // used for iOS only
    case sidebar = "TOGGLE_SIDEBAR" // used for Mac only

    #if targetEnvironment(macCatalyst)
    var identifier: NSToolbarItem.Identifier { return NSToolbarItem.Identifier(rawValue: self.rawValue) }
    var paletteLabel: String { return NSLocalizedString(self.rawValue + "_PALETTE_LABEL", comment: "") }
    #endif
}

extension RecipesViewController {
    /**
     Create an instance of a specified UIBarButton item.
     - Parameter identifier: type of the UIBarButton to use (See BarButtonType)
     - Return: instance of the UIBarButton
     */
    func barButtonForType(_ identifier: BarButtonType) -> UIBarButtonItem? {
        switch identifier {
        case .share:
            return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.shareRecipe))
        case .settings:
            // This is only available on iOS. MacOS does not yet support SF Symbols.
            let configuration = UIImage.SymbolConfiguration(weight: .black)
            return UIBarButtonItem(image: UIImage(systemName: "gear", withConfiguration: configuration),
                                   style: .plain, target: self, action: #selector(self.showPreferencesiOS))
        case .sidebar:
            return self.splitViewController?.displayModeButtonItem
        }
    }
}

// MARK: - Bar Button Callbacks

extension RecipesViewController {
    /// Show the share sheet.
    @objc func shareRecipe(item: Any) {
        // Disable the toolbar items if we request the login information
        guard self.presentedViewController == nil else { return }

        guard let splitViewController = self.splitViewController as? SplitViewController else { return }

        if let data = splitViewController.recipeDetailController?.pdfRepresentation() {
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Recipe.pdf")
            try? data.write(to: url)
            let acViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            // item as? UIBarButtonItem is None for all platforms other then iPad OS
            acViewController.popoverPresentationController?.barButtonItem = item as? UIBarButtonItem
            self.present(acViewController, animated: true)
        }
    }

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
}
