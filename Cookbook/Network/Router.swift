//
//  Router.swift
//  Cookbook
//
//  Created by David Klopp on 22.12.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

/*
 API Documentation:
 > Note: All Path should be relative to /apps/cookbook

 +-----------------------------------------+-----------+-----------------------------+------------------------+--------+
 |               Description               |  Method   |             Path            |        Parameters      | Format |
 +-----------------------------------------+-----------+-----------------------------+------------------------+--------+
 | List all recipes                        |    get    |   api/recipes               |        keywords        |  json  |
 | Get an image for a recipe               |    get    |   /recipes/{id}/image       |   size (thumb, full)   | binary |
 | List all recipe information             |    get    |   api/recipe/{id}           |                        |  json  |
 | Delete a recipe                         |   delete  |   api/recipe/{id}           |                        |        |
 | Change the recipe information           |    put    |   api/recipe/{id}           |      recipe details    |        |
 +-----------------------------------------+-----------+-----------------------------+------------------------+--------+
 
 */
import Foundation
import Alamofire

struct MissingCredentialsError: Error {

}

enum Router: URLRequestConvertible {
    case allRecipes(paramters: Parameters)
    case image(rid: Int, thumb: Bool)
    case recipe(rid: Int)
    case delete(rid: Int)
    case update(rid: Int, recipeDetails: [String: Any])
    case create(recipeDetails: [String: Any])

    var method: HTTPMethod {
        switch self {
        case .allRecipes, .image, .recipe:
            return .get
        case .update:
            return .put
        case .delete:
            return .delete
        case .create:
            return .post
        }
    }

    var path: String {
        switch self {
        case .allRecipes, .create:
            return "api/recipes"
        case .image(let rid, _):
            return "/recipes/\(rid)/image"
        case .recipe(let rid), .delete(let rid), .update(let rid, _):
            return "api/recipes/\(rid)"
        }
    }

    func asURLRequest() throws -> URLRequest {
        guard let server = loginCredentials.server,
            let user = loginCredentials.username,
            let password = loginCredentials.password else {
                throw MissingCredentialsError()
        }

        let baseURLString = "\(server)/apps/cookbook"
        let url = try baseURLString.asURL()
        var urlRequest = URLRequest(url: url.appendingPathComponent(self.path))
        urlRequest.httpMethod = self.method.rawValue
        if let authorizationHeader = Request.authorizationHeader(user: user, password: password) {
            urlRequest.setValue(authorizationHeader.value, forHTTPHeaderField: authorizationHeader.key)
        }

        switch self {
        case .allRecipes(let parameters):
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .image(_, let thumb):
            let parameters = thumb ? ["size": "thumb"] : ["size": "full"]
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        case .recipe:
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest = try URLEncoding.default.encode(urlRequest, with: nil)
        case .update(_, let recipeDetails), .create(let recipeDetails):
            urlRequest.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest = try URLEncoding.default.encode(urlRequest, with: recipeDetails)
        case .delete:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: nil)
        }
        return urlRequest
    }
}
