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
    /// The image url on the NextCloud belongig to the recipe.
    var imageURL: String
    /// The image name.
    var name: String
    /// The user name.
    var userID: String
    /// The unique recipeID.
    var recipeID: Int

    /// Shared image cache.
    static private var thumbnailCache: [Int: UIImage] = [:]

    /// Keep a cached version of the thumbnail image because the thumbnail might be requiered more often and we do not
    /// want to trust that AlamofireImage will cache the image all the time. Futhermore this reduces lets us access the
    // image synchronous.
    var thumbnail: UIImage? {
        get { return Recipe.thumbnailCache[self.recipeID] }
        set (image) { Recipe.thumbnailCache[self.recipeID] = image }
    }

    static let descriptionKeys = [NSLocalizedString("DESCRIPTION", comment: ""),
                                  NSLocalizedString("SOURCE", comment: ""),
                                  NSLocalizedString("PREPARATION_TIME", comment: ""),
                                  NSLocalizedString("COOKING_TIME", comment: ""),
                                  NSLocalizedString("TOTAL_TIME", comment: ""),
                                  NSLocalizedString("SERVINGS", comment: "")]

    /**
     Get the simple representation of the recipe as dicitonary.
     - Return: a dictionary with the basic recipe information (excluding the recipe details).
     */
    func toDict() -> [String: Any] {
        return ["name": self.name, "recipeID": self.recipeID, "imageURL": imageURL, "userID": userID]
    }

    /**
     Create a recipe from its simple dictionary representation.
     - Return: Recipe instance.
    */
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

    /**
     Load the corersponding recipe image either as thumbnail or in full resolution.
     - Parameter completionHandler: closure with the attached image data or nil called after the request is completed
     - Parameter thumb: true to request the thumbnail or false to request the full version of the image
     - Return: RequestReceipt instance to cancel the loading request.
    */
    @discardableResult
    func loadImage(completionHandler: @escaping ImageCompletionHandler, thumb: Bool = true) -> RequestReceipt? {
        let router = Router.image(rid: self.recipeID, thumb: thumb)

        // Download the image.
        return ImageDownloader.default.download([router], completion: { (response: AFIDataResponse<Image>) in
            // Cache the thumbnail image.
            let image = response.value
            if thumb {
                self.thumbnail = image
            }
            completionHandler(image)
        }).first
    }

    /**
     Parse the recipe details dictionary and return the description data with corresponding keys as arrays.
     - Parameter recipeDetails: the complete recipe details to parse (only a subset of all entries is used)
    */
    static func parseDescriptionValuesFor(recipeDetails: [String: Any]) -> ([String], [String]) {
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

    /**
     Load the recipe details as json array from the server.
     - Parameter completionHandler: closure called when the recipe details are loaded successfully
     - Parameter errorHandler: closure called when an error occured.
    */
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

    /**
     Load all recipes from the server.
     - Parameter completionHandler: closure with all Recipe instances called when the data is loaded successfully
     - Parameter errorHandler: closure called when an error occured.
    */
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
                        // Fix: Cookbook 0.63
                        let rid = entry["recipe_id"] as? Int ?? (entry["recipe_id"] as? String)?.intValue

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

    /**
     Update an existing recipe with new recipe details.
     - Parameter recipeDetails: the new recipe detail information
     - Parameter completionHandler: closure called when the update operation was successfull
     - Parameter errorHandler: closure called when an error occured
    */
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

    /**
     Delete an existing recipe from the server.
     - Parameter completionHandler: closure called when the delete operation was successfull
     - Parameter errorHandler: closure called when an error occured.
    */
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

    /**
     Create a new recipe.
     - Parameter recipeDetails: the recipe detail information for this new recipe
     - Parameter completionHandler: closure called when the update operation was successfull
     - Parameter errorHandler: closure called when an error occured.
    */
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
