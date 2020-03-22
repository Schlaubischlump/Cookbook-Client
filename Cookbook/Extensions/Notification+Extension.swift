//
//  Notification+Extension.swift
//  Cookbook
//
//  Created by David Klopp on 07.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation

extension Notification.Name {
    /// Called after a login attempt. Note this does not mean the login was successfull.
    static let login = Notification.Name("com.cookbook.login.notification")
    /// Called after a successfull logout.
    static let logout = Notification.Name("com.cookbook.logout.notification")
    /// Called to force a reload of the whole recipe master and thereby recipe detail views.
    static let reload = Notification.Name("com.cookbook.reload.notification")

    /// Called before the request to load all recipes is send to the server.
    static let willLoadRecipes = Notification.Name("com.cookbook.willLoadRecipes.notification")
    /// Called when all recipes are loaded from the server (excluding the recipe details).
    static let didLoadRecipes = Notification.Name("com.cookbook.didLoadRecipes.notification")

    /// Called when the recipe detail view starts loading the data from the server.
    static let willLoadRecipeDetails = Notification.Name("com.cookbook.willLoadRecipeDetails.notification")
    /// Called when the recipe detail view finished loading.
    static let didLoadRecipeDetails = Notification.Name("com.cookbook.didLoadRecipeDetails.notification")

    /// Called when the user starts to create a new recipe.
    static let willAddRecipe = Notification.Name("com.cookbook.willAddRecipe.notification")
    /// Called when a recipe should be added. This includes the cases:
    /// 1. Sucessfully added the recipe on the server: userInfo = [recipeID: Int, details: [String: Any]]
    /// 2. Error while changing the recipe data on the server: userInfo = nil
    /// 3. User canceled the recipe creation: userInfo = nil
    static let didAddRecipe = Notification.Name("com.cookbook.didAddRecipe.notification")
    /// Called when the user starts editing a recipe.
    static let willEditRecipe = Notification.Name("com.cookbook.willEditRecipe.notification")
    /// Called when a recipe was edited. This includes the cases:
    /// 1. Sucessfully edited the recipe on the server: userInfo = [recipeID: Int, details: [String: Any]]
    /// 2. Error while changing the recipe data on the server: userInfo = nil
    static let didEditRecipe = Notification.Name("com.cookbook.didEditRecipe.notification")
    /// Called when a recipe was deleted. This includes the cases:
    /// 1. Sucessfully deleted the recipe on the server: userInfo = [recipeID: Int]
    /// 2. Error while changing the recipe data on the server: userInfo = nil
    static let didRemoveRecipe = Notification.Name("com.cookbook.didRemoveRecipe.notification")
}
