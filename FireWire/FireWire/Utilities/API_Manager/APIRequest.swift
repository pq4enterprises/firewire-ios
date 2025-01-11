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

    func callApi<T: Codable>(
        apiEndPoint: String?,
        payload: JSON? = nil,
        expect: T.Type,
        requestType: String = APIConstants.POST, // Default to POST if not specified
        completionHandler: @escaping DataCompletionBlock
    ) {
        var urlString = APIEndpoints.baseURL + (apiEndPoint ?? "")
        let accessToken = UserDefaults.standard.string(forKey: "token")

        // For GET request, append parameters to the URL if provided
        if requestType == APIConstants.GET, let payload = payload, !payload.isEmpty {
            var urlComponents = URLComponents(string: urlString)
            urlComponents?.queryItems = payload.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            urlString = urlComponents?.url?.absoluteString ?? urlString
        }

        // Perform the API request
        URLSession.shared.request(url: URL(string: urlString),
                                  httpMethod: requestType,
                                  authTokenString: accessToken ?? "",
                                  headers: APIConstants.headers,
                                  payload: requestType == APIConstants.POST ?  payload : nil,
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
