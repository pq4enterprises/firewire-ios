//
//  APIRequest.swift
//  JP_apiSample
//
//  Created by prithviraj on 19/10/22.
//

import UIKit
import XMLCoder

typealias JSON = [String: Any]

public class APIRequest {
    typealias DataCompletionBlock = (_ response: Any?, _ statusCode: Int?, _ error: String?) -> Void

    // Generic POST API request handler
    func callApi<T: Codable>(
        apiEndPoint: String?,
        payload: JSON? = nil,
        expect: T.Type,
        requestType: String = APIConstants.POST,
        completionHandler: @escaping DataCompletionBlock
    ) {
        let url = APIEndpoints.baseURL + (apiEndPoint ?? "")
        let accessToken = UserDefaults.standard.string(forKey: "token")

        // Perform the API request
        URLSession.shared.request(url: URL(string: url),
                                  httpMethod: requestType,
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
        parameters: [String: Any]?,
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
                                  payload: nil, // No payload for GET requests
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

    func fetchRSS<T: Codable>(apiEndPoint: String, modelType: T.Type, completionHandler: @escaping DataCompletionBlock) {
        guard let url = URL(string: apiEndPoint) else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, error.localizedDescription)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, "No data found")
                }
                return
            }

            // Decode the fetched XML data into the model
            do {
                // Use XMLDecoder to parse the XML data
                let decoder = XMLDecoder()
                let model = try decoder.decode(modelType.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(model, nil, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, error.localizedDescription)
                }
            }
        }

        task.resume()
    }
}
