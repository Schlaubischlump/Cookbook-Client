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
 | List all recipes                        |    get    |           /recipes          |        keywords        |  json  |
 | Get an image for a recipe               |    get    |      /recipes/{id}/image    |   size (thumb, full)   | binary |
 | List all recipe information             |    get    |         /recipe/{id}        |                        |  json  |
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

    var method: HTTPMethod {
        switch self {
        case .allRecipes:
            return .get
        case .recipe:
            return .get
        case .image:
            return .get
        }
    }

    var path: String {
        switch self {
        case .allRecipes:
            return "/recipes"
        case .recipe(let rid):
            return "/recipes/\(rid)"
        case .image(let rid, _):
            return "/recipes/\(rid)/image"
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
            let params = thumb ? ["size": "thumb"] : ["size": "full"]
            urlRequest = try URLEncoding.default.encode(urlRequest, with: params)
        case .recipe:
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest = try URLEncoding.default.encode(urlRequest, with: nil)
        }
        return urlRequest
    }
}
