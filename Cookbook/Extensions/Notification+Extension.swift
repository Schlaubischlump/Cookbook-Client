//
//  Notification+Extension.swift
//  Cookbook
//
//  Created by David Klopp on 07.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let login = Notification.Name("com.cookbook.login.notification")
    static let logout = Notification.Name("com.cookbook.logout.notification")
    static let reload = Notification.Name("com.cookbook.reload.notification")

    // Called when a MBPorgess HUD is displayed or dismissed.
    static let showsHud = Notification.Name("com.cookbook.showsHud.notification")
    static let hidesHud = Notification.Name("com.cookbook.hidesHud.notification")

    // Called when the recipe detail view finished loading.
    static let willLoadRecipeDetails = Notification.Name("com.cookbook.willLoadRecipeDetails.notification")
    static let didLoadRecipeDetails = Notification.Name("com.cookbook.didLoadRecipeDetails.notification")
}
