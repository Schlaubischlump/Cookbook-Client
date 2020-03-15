//
//  AppDelegate+UIMenu.swift
//  Cookbook
//
//  Created by David Klopp on 15.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension AppDelegate {
    // MARK: - Menubar

    /**
     Create the menubar items.
     */
    override func buildMenu(with builder: UIMenuBuilder) {
       super.buildMenu(with: builder)

       // Add a custom Preferences... window.
       let prefrencesCommand = UIKeyCommand(input: ",", modifierFlags: [.command],
                                            action: #selector(self.showPreferences))
       prefrencesCommand.title = NSLocalizedString("PREFERENCES_MENU", comment: "")
       let prefrencesCommandMenu = UIMenu(title: prefrencesCommand.title,
                                          image: nil, identifier: UIMenu.Identifier("preferences"),
                                          options: .displayInline, children: [prefrencesCommand])
       builder.insertSibling(prefrencesCommandMenu, afterMenu: .about)

    }

    /**
    Create a new preference window on macOS or bring the existing one to the front.
    */
    @objc func showPreferences(_ sender: Any, _ mainViewController: UIViewController?) {
       //
       let uiApp = UIApplication.shared
       let windowScenes = uiApp.connectedScenes.filter {
           (($0 as? UIWindowScene)?.delegate as? PreferencesSceneDelegateMac) != nil
       }

       // Prevent multiple setting windows.
       if windowScenes.first?.delegate as? PreferencesSceneDelegateMac != nil {
           // TODO: Bring the old preference window to the front... Is there a way in catalyst without AppKit glue?
           // This should work if catalyst supports the full UIKit API.
           //uiApp.requestSceneSessionActivation(windowScenes.first?.session, userActivity: nil, options: nil)
       } else {
           // Create a new preference window.
           let activity = NSUserActivity(activityType: ActivityType.preferences)
           uiApp.requestSceneSessionActivation(nil, userActivity: activity, options: nil)
       }
    }
}
