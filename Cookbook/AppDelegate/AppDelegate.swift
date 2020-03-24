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

/**
 All available NSUserActivity types used in this application.
 */
struct ActivityType {
    /// The activity type used on macOS to present the settings window.
    static let preferences: String = "nextcloud.cookbook.preferences"
    /// The default activity type used to create a new window.
    static let `default`: String = "nextcloud.cookbook.default"
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
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)

        // Allow opening a preference window on macOS.
        #if targetEnvironment(macCatalyst)
        if options.userActivities.first?.activityType == ActivityType.preferences {
            config.delegateClass = PreferencesSceneDelegateMac.self
            config.storyboard = UIStoryboard(name: "Preferences_Mac", bundle: Bundle.main)
            return config
        }
        #endif

        // Default case, just a new window.
        config.delegateClass = SceneDelegate.self
        config.storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        return config
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
}
