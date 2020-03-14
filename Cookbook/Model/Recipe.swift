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

/*
// MARK: - HTML / PDF export
extension Recipe {
    /// Return a html representation of the recipe as string.
    func loadHTMLRepresentation(completionHandler: @escaping HTMLComplectionHandler,
                                errorHandler: @escaping ErrorHandler = { _ in }) {
        // Load recipe html template from the main bundle.
        guard let htmlTemplate = Bundle.main.path(forResource: "recipe_template", ofType: "html") else { return }

        var possibleHtmlContent: String?
        do {
            possibleHtmlContent = try String(contentsOfFile: htmlTemplate)
        } catch let error {
            errorHandler(error)
        }

        guard var htmlContent = possibleHtmlContent else { return }

        htmlContent = htmlContent.replacingOccurrences(of: "#TITLE#", with: self.name)
            .replacingOccurrences(of: "#TITLE_TOOLS#", with: NSLocalizedString("TOOLS", comment: ""))
            .replacingOccurrences(of: "#TITLE_INGREDIENTS#", with: NSLocalizedString("INGREDIENTS", comment: ""))
            .replacingOccurrences(of: "#TITLE_INSTRUCTIONS#", with: NSLocalizedString("INSTRUCTIONS", comment: ""))

        // Synchronise loading requests.
        let group = DispatchGroup()

        // Load an place the image inside the recipe.
        //if includeImage {
        //    group.enter()
        //    self.loadImage(completionHandler: { image in
        //        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("image.png")
        //        try? image?.pngData()?.write(to: url)
        //        htmlContent = htmlContent.replacingOccurrences(of: "#IMAGE_DATA#", with: url.absoluteString)
        //        group.leave()
        //   }, thumb: false)
        //} else {
        //    htmlContent = htmlContent.replacingOccurrences(of: "#IMAGE_DATA#", with: "")
        //}

        // Load the recipe details.
        var error: Error?
        group.enter()
        self.loadRecipeDetails(completionHandler: { details in
            guard let details = details else { return }

            // Add the description, tools and ingredients and instructions.
            let (descriptionKeys, descriptionData) = Recipe.parseDescriptionValuesFor(jsonArray: details)
            let desc = zip(descriptionKeys, descriptionData).map { "<p><strong>\($0): </strong>\($1)</p>\n" }.joined()
            let tools = (details["tool"] as? [String])?.map { "<li>\($0)</li>\n" }.joined()
            let ingredients = (details["recipeIngredient"] as? [String])?.map { "<li>\($0)</li>\n" }.joined()
            let instructions = (details["recipeInstructions"] as? [String])?.map { "<li>\($0)</li></br>\n" }.joined()

            htmlContent = htmlContent.replacingOccurrences(of: "#RECIPE_DETAILS#", with: desc)
            htmlContent = htmlContent.replacingOccurrences(of: "#TOOLS#", with: tools ?? "")
            htmlContent = htmlContent.replacingOccurrences(of: "#INGREDIENTS#", with: ingredients ?? "")
            htmlContent = htmlContent.replacingOccurrences(of: "#INSTRUCTIONS#", with: instructions ?? "")
            group.leave()
        }, errorHandler: { err in
            error = err
            group.leave()
        })

        // Wait for all tasks to finish
        group.notify(queue: DispatchQueue.main) {
            if let loadingError = error {
                errorHandler(loadingError)
            } else {
                completionHandler(htmlContent)
            }
        }
    }
}*/
