//
//  Recipe.swift
//  Cookbook
//
//  Created by David Klopp on 22.12.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage
import UIKit

typealias ImageCompletionHandler = (_ image: Image?) -> Void
typealias DetailsCompletionHandler = (_ json: [String: Any]?) -> Void
typealias ErrorHandler = (_ error: Error) -> Void
typealias RecipesCompletionHandler = (_ recipes: [Recipe]) -> Void
typealias UpdateCompletionHandler = () -> Void
typealias CreateCompletionHandler = (Int) -> Void

enum RecipeError: Error {
    case noData
    case invalidJson
}

class Recipe {
    var imageURL: String
    var name: String
    var userID: String
    var recipeID: Int
    /// Keep a cached version of the thumbnail image.
    var thumbnail: UIImage?

    static let descriptionKeys = [NSLocalizedString("DESCRIPTION", comment: ""),
                                  NSLocalizedString("SOURCE", comment: ""),
                                  NSLocalizedString("PREPARATION_TIME", comment: ""),
                                  NSLocalizedString("COOKING_TIME", comment: ""),
                                  NSLocalizedString("TOTAL_TIME", comment: ""),
                                  NSLocalizedString("SERVINGS", comment: "")]

    /// Return a dictionary with the basic recipe information (excluding the recipe details).
    func toDict() -> [String: Any] {
        return ["name": self.name, "recipeID": self.recipeID, "imageURL": imageURL, "userID": userID]
    }

    /// Create a recipe from the dictionary
    static func from(dict: [String: Any]) -> Recipe? {
        if let imageURL = dict["imageURL"] as? String, let name = dict["name"] as? String,
           let recipeID = dict["recipeID"] as? Int, let userID = dict["userID"] as? String {
                return Recipe(imageURL: imageURL, name: name, userID: userID, recipeID: recipeID)
        }
        return nil
    }

    // MARK: - Helper

    /**
     Delete the currently cached thumb and fullSize images cached by AlamoreFire.
     - Return: true if at least one image was removed, false otherwise.
     */
    @discardableResult
    private func clearCachedImages() -> Bool {
        var removedImage = false
        let cache = ImageDownloader.default.imageCache as? AutoPurgingImageCache
        let imageThumbRoute = Router.image(rid: self.recipeID, thumb: false)
        if let thumbRequest = imageThumbRoute.urlRequest {
            removedImage = cache?.removeImages(matching: thumbRequest) ?? false
        }
        let imageFullSizeRoute = Router.image(rid: self.recipeID, thumb: true)
        if let fullSizeRequest = imageFullSizeRoute.urlRequest {
            removedImage = cache?.removeImages(matching: fullSizeRequest) ?? false || removedImage
        }
        removedImage = removedImage || (self.thumbnail != nil)
        self.thumbnail = nil
        return removedImage
    }

    // MARK: - Constructor

    init(imageURL: String, name: String, userID: String, recipeID: Int) {
        self.imageURL = imageURL
        self.name = name
        self.userID = userID
        self.recipeID = recipeID
    }

    // MARK: - Data loading

    /// Load the corersponding recipe image either as thumbnail or in full resolution.
    @discardableResult
    func loadImage(completionHandler: @escaping ImageCompletionHandler, thumb: Bool = true) -> RequestReceipt? {
        let router = Router.image(rid: self.recipeID, thumb: thumb)

        // Download the image.
        return ImageDownloader.default.download([router], completion: { (response: AFIDataResponse<Image>) in
            guard let image = response.value else {
                completionHandler(nil)
                return
            }
            // Cache the thumbnail image.
            if thumb {
                self.thumbnail = image
            }
            completionHandler(image)
        }).first
    }

    /// Parse the json dictionary and return the description data with corresponding keys as arrays.
    static func parseDescriptionValuesFor(jsonArray recipeDetails: [String: Any]) -> ([String], [String]) {
        let servings: Int? = (recipeDetails["recipeYield"] as? Int)

        let descriptionData: [String] = [(recipeDetails["description"] as? String ?? ""),
                                         (recipeDetails["url"] as? String ?? ""),
                                         ((recipeDetails["prepTime"] as? String)?.readableTime() ?? ""),
                                         ((recipeDetails["cookTime"] as? String)?.readableTime() ?? ""),
                                         ((recipeDetails["totalTime"] as? String)?.readableTime() ?? ""),
                                         (servings != nil) ? String(servings!) : ""]
        let mask = descriptionData.map { !$0.isEmpty }
        return (Recipe.descriptionKeys.booleanMask(mask), descriptionData.booleanMask(mask))
    }

    /// Load the recipe details as json array. Use parseDescriptionValuesFor(jsonArray:) to parse the Data.
    func loadRecipeDetails(completionHandler: @escaping DetailsCompletionHandler,
                           errorHandler: @escaping ErrorHandler = { _ in }) {
        let router = Router.recipe(rid: self.recipeID)
        Session
            .default
            .request(router)
            .validate(statusCode: 200..<300)
            .responseData { response in
                switch response.result {
                case .success:
                    guard let data = response.data else {
                        errorHandler(RecipeError.noData)
                        return
                    }
                    let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: [])

                    guard let jsonArray = jsonResponse as? [String: Any] else {
                        errorHandler(RecipeError.invalidJson)
                        return
                    }

                    completionHandler(jsonArray)
                case .failure(let error):
                    errorHandler(error)
                }
        }
    }

    /// Load all recipes from the server.
    static func loadRecipes(completionHandler: @escaping RecipesCompletionHandler,
                            errorHandler: @escaping ErrorHandler = { _ in }) {
        let router = Router.allRecipes(paramters: ["keywords": ""])
        Session
            .default
            .request(router)
            .validate(statusCode: 200..<300)
            .responseData { (response) in
                switch response.result {
                case .success:
                    // Parse the json response.
                    guard let data = response.data else {
                        errorHandler(RecipeError.noData)
                        return
                    }

                    let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: [])

                    guard let jsonArray = jsonResponse as? [[String: Any]] else {
                        errorHandler(RecipeError.invalidJson)
                        return
                    }

                    var recipes: [Recipe] = []
                    for entry in jsonArray {
                        let img = (entry["image_url"] as? String) ?? ""
                        let name = entry["name"] as? String
                        let user = entry["user_id"] as? String
                        let rid = (entry["recipe_id"] as? String)?.intValue

                        if let name = name, let user = user, let rid = rid {
                            let recipe = Recipe(imageURL: img, name: name, userID: user, recipeID: rid)
                            recipes.append(recipe)
                        }
                    }
                    // Sort the recipes by name.
                    recipes.sort(by: {
                        $0.name.localizedCaseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending
                    })

                    completionHandler(recipes)
                case .failure(let error):
                    errorHandler(error)
                }
        }
    }

    // MARK: - Add / update / delete

    /// Update an existing recipe with new recipe details.
    func update(_ recipeDetails: [String: Any], completionHandler: @escaping UpdateCompletionHandler,
                errorHandler: @escaping ErrorHandler = { _ in }) {
        let router = Router.update(rid: self.recipeID, recipeDetails: recipeDetails)
        Session
            .default
            .request(router)
            .validate(statusCode: 200..<300)
            .responseData { (response) in
                switch response.result {
                case .success:
                    self.clearCachedImages()
                    completionHandler()
                case .failure(let error):
                    errorHandler(error)
            }
        }
    }

    /// Delete an existing recipe from the server.
    func delete(_ completionHandler: @escaping UpdateCompletionHandler,
                errorHandler: @escaping ErrorHandler = { _ in }) {
        let router = Router.delete(rid: self.recipeID)
        Session
            .default
            .request(router)
            .validate(statusCode: 200..<300)
            .responseData { (response) in
                switch response.result {
                case .success:
                    self.clearCachedImages()
                    completionHandler()
                case .failure(let error):
                    errorHandler(error)
            }
        }
    }

    /// Create a new recipe.
    static func create(_ recipeDetails: [String: Any], completionHandler: @escaping CreateCompletionHandler,
                       errorHandler: @escaping ErrorHandler = { _ in }) {
        let router = Router.create(recipeDetails: recipeDetails)
        Session
            .default
            .request(router)
            .validate(statusCode: 200..<300)
            .responseData { (response) in
                switch response.result {
                case .success:
                    if let data = response.data, let recipeID = String(bytes: data, encoding: .utf8)?.intValue {
                        completionHandler(recipeID)
                    }
                case .failure(let error):
                    errorHandler(error)
            }
        }
    }

}
