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
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var displayModeButtonItem: UIBarButtonItem {
        // Catalyst does not support SF Symbols yet and splitViewController.displayModeButtonItem is not implemented.
        #if targetEnvironment(macCatalyst)
        let size = CGSize(width: 44, height: 44)
        return UIBarButtonItem(image: UIImage(named: "sidebar.left")?.af_imageAspectScaled(toFit: size),
                               style: .plain, target: self, action: #selector(self.toggleSidebar))
        #else
        return super.displayModeButtonItem
        #endif
    }

    @objc func toggleSidebar(item: Any) {
        // Make sure to make the master view controller the new fist responder.
        let viewController = self.viewControllers.first
        var view = viewController?.view
        if let navController = viewController as? UINavigationController {
            view = navController.topViewController?.view
        }

        view?.becomeFirstResponder()

        // Toggle the sidebar button.
        UIView.animate(withDuration: 0.25, animations: {
            if self.preferredDisplayMode == .primaryHidden {
                self.preferredDisplayMode = .allVisible
            } else {
                self.preferredDisplayMode = .primaryHidden
            }

            // Force a relayout of the detailView
            let viewController = self.viewControllers.last
            var view = viewController?.view
            if let navController = viewController as? UINavigationController {
                view = navController.topViewController?.view
            }
            view?.setNeedsLayout()
            view?.layoutIfNeeded()
        })
    }
}
