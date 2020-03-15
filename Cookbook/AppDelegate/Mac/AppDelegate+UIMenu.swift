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

        let searchCommand = UIKeyCommand(input: "f", modifierFlags: [.command], action: #selector(self.activateSearch))
        searchCommand.title = NSLocalizedString("SEARCH_MENU", comment: "")
        let searchCommandMenu = UIMenu(title: searchCommand.title,
                                       image: nil, identifier: UIMenu.Identifier("find"),
                                       options: .displayInline, children: [searchCommand])

        builder.insertSibling(prefrencesCommandMenu, afterMenu: .about)
        builder.insertChild(searchCommandMenu, atEndOfMenu: .file)
    }

    /**
    Create a new preference window on macOS or bring the existing one to the front.
    */
    @objc func showPreferences(_ sender: Any) {
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

    /**
     Activate the searchbar to find a recipe
     */
    @objc func activateSearch(sender: Any) {
        let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        let splitViewController = window?.rootViewController as? SplitViewController
        splitViewController?.recipesMasterController?.searchController.searchBar.becomeFirstResponder()
    }
}
