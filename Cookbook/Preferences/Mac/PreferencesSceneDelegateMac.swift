//
//  PreferencesSceneDelegate.swift
//  Cookbook
//
//  Created by David Klopp on 06.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Preference Scene Delegate

class PreferencesSceneDelegateMac: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func sceneWillEnterForeground(_ scene: UIScene) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        guard let viewController = window?.rootViewController as? PreferencesViewControllerMac else { return }

        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
        let height: CGFloat = viewController.logoutButton.frame.maxY + 50
        let width: CGFloat = 500
        windowScene.sizeRestrictions?.minimumSize = CGSize(width: width, height: height)
        windowScene.sizeRestrictions?.maximumSize = CGSize(width: width, height: height)
    }
}
