//
//  APIRequest.swift
//  JP_apiSample
//
//  Created by prithviraj on 19/10/22.
//

import UIKit

typealias JSON = [String: Any]

public class APIRequest {
    typealias DataCompletionBlock = (_ response: Any?, _ statusCode: Int?, _ error: String?) -> Void

    // Generic POST API request handler
    func callApi<T: Codable>(
        apiEndPoint: String?,
        payload: JSON? = nil,
        expect: T.Type,
        completionHandler: @escaping DataCompletionBlock
    ) {
        let url = APIEndpoints.baseURL + (apiEndPoint ?? "")
        let accessToken = UserDefaults.standard.string(forKey: "token")

        // Perform the API request
        URLSession.shared.request(url: URL(string: url),
                                  httpMethod: APIConstants.POST,
                                  authTokenString: accessToken ?? "",
                                  headers: APIConstants.headers,
                                  payload: payload,
                                  expecting: expect.self)
        { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    completionHandler(response, nil, nil)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(nil, nil, error.localizedDescription)
                }
            }
        }
    }

    // Generic GET API request handler
    func callGetApi<T: Codable>(
        apiEndPoint: String?,
        parameters: [String: Any]?,  // parameters for GET request
        expect: T.Type,
        completionHandler: @escaping DataCompletionBlock
    ) {
        var urlString = APIEndpoints.baseURL + (apiEndPoint ?? "")
        let accessToken = UserDefaults.standard.string(forKey: "token")

        // Append parameters to URL if they exist
        if let parameters = parameters, !parameters.isEmpty {
            var urlComponents = URLComponents(string: urlString)
            urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            urlString = urlComponents?.url?.absoluteString ?? urlString
        }

        // Perform the API request
        URLSession.shared.request(url: URL(string: urlString),
                                  httpMethod: APIConstants.GET,
                                  authTokenString: accessToken ?? "",
                                  headers: APIConstants.headers,
                                  payload: nil,  // No payload for GET requests
                                  expecting: expect.self)
        { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    completionHandler(response, nil, nil)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(nil, nil, error.localizedDescription)
                }
            }
        }
    }

}
