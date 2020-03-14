//
//  AppDelegate.swift
//  Cookbook
//
//  Created by David Klopp on 22.12.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import UIKit
import Alamofire

// MARK: UserActivitys

struct ActivityType {
    static let preferences: String = "nextcloud.cookbook.preferences"
    static let main: String = "nextcloud.cookbook.default"
}

struct ActivityTitle {
    static let newWindow: String = "openWindow"
}

// MARK: - UIApplication Delegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        let configuration = UISceneConfiguration(name: "Default Configuration",
                                                 sessionRole: connectingSceneSession.role)

        // Allow opening a preference window on macOS.
        #if targetEnvironment(macCatalyst)
        if options.userActivities.first?.activityType == ActivityType.preferences {
            configuration.delegateClass = PreferencesSceneDelegateMac.self
            configuration.storyboard = UIStoryboard(name: "Preferences_Mac", bundle: Bundle.main)
            return configuration
        }
        #endif

        // Default case, just a new window.
        configuration.delegateClass = SceneDelegate.self
        configuration.storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        return configuration
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after
        // application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Credentials.setDefaultInformation()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        try? loginCredentials.updateStoredInformation()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        try? loginCredentials.updateStoredInformation()
    }

    // MARK: - Menubar
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
     Show the preferences pane.
     */
    @objc func showPreferences(_ sender: Any) {
        #if targetEnvironment(macCatalyst)
        // Show preferences window on macOS.
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
        #else
        // Present a settings view controller on iOS.
        let settingsViewController = PreferencesViewControlleriOS()
        settingsViewController.beginSheetModal { [weak settingsViewController] response in
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
