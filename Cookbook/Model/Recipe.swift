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

typealias HTMLComplectionHandler = (_ html: String) -> Void
typealias ImageCompletionHandler = (_ image: Image?) -> Void
typealias DetailsCompletionHandler = (_ json: [String: Any]?) -> Void
typealias ErrorHandler = (_ error: Error) -> Void
typealias RecipesCompletionHandler = (_ recipes: [Recipe]) -> Void

enum RecipeLoadingError: Error {
    case noData
    case invalidJson
}

struct Recipe {
    var imageURL: String
    var name: String
    var userID: String
    var recipeID: Int

    var description: String {
        return "\(self.name)"
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
        return ImageDownloader.default.download([router], completion: { (response: DataResponse<Image>) in
            guard let image = response.value else { return }
            completionHandler(image)
        }).first
    }

    /// Parse the json dictionary and return the description data with corresponding keys as arrays.
    static func parseDescriptionValuesFor(jsonArray recipeDetails: [String: Any]) -> ([String], [String]) {
        let servings: Int? = (recipeDetails["recipeYield"] as? Int)
        let descriptionKeys = [NSLocalizedString("DESCRIPTION", comment: ""),
                               NSLocalizedString("SOURCE", comment: ""),
                               NSLocalizedString("PREPARATION_TIME", comment: ""),
                               NSLocalizedString("COOKING_TIME", comment: ""),
                               NSLocalizedString("TOTAL_TIME", comment: ""),
                               NSLocalizedString("SERVINGS", comment: "")]
        let descriptionData: [String] = [(recipeDetails["description"] as? String ?? ""),
                                         (recipeDetails["url"] as? String ?? ""),
                                         ((recipeDetails["prepTime"] as? String)?.readableTime() ?? ""),
                                         ((recipeDetails["cookTime"] as? String)?.readableTime() ?? ""),
                                         ((recipeDetails["totalTime"] as? String)?.readableTime() ?? ""),
                                         (servings != nil) ? String(servings!) : ""]
        let mask = descriptionData.map { !$0.isEmpty }
        return (descriptionKeys.booleanMask(mask), descriptionData.booleanMask(mask))
    }

    /// Load the recipe details as json array. Use parseDescriptionValuesFor(jsonArray:) to parse the Data.
    func loadRecipeDetails(completionHandler: @escaping DetailsCompletionHandler,
                           errorHandler: @escaping ErrorHandler = { _ in }) {
        let router = Router.recipe(rid: self.recipeID)
        SessionManager
            .default
            .request(router)
            .validate(statusCode: 200..<300)
            .responseData { (response) in
                switch response.result {
                case .success:
                    guard let data = response.data else {
                        errorHandler(RecipeLoadingError.noData)
                        return
                    }
                    let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: [])

                    guard let jsonArray = jsonResponse as? [String: Any] else {
                        errorHandler(RecipeLoadingError.invalidJson)
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
        SessionManager
            .default
            .request(router)
            .validate(statusCode: 200..<300)
            .responseData { (response) in
                switch response.result {
                case .success:
                    // Parse the json response.
                    guard let data = response.data else {
                        errorHandler(RecipeLoadingError.noData)
                        return
                    }

                    let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: [])

                    guard let jsonArray = jsonResponse as? [[String: Any]] else {
                        errorHandler(RecipeLoadingError.invalidJson)
                        return
                    }

                    var recipes: [Recipe] = []
                    for entry in jsonArray {
                        let img = (entry["image_url"] as? String) ?? ""
                        let name = entry["name"] as? String
                        let user = entry["user_id"] as? String
                        let rid = entry["recipe_id"] as? Int
                        if let name = name, let user = user, let rid = rid {
                            let recipe = Recipe(imageURL: img, name: name, userID: user, recipeID: rid)
                            recipes.append(recipe)
                        }
                    }

                    completionHandler(recipes)
                case .failure(let error):
                    errorHandler(error)
                }
        }
    }
}
