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

    // Generic API request handler
    func callApi<T: Codable>(
        apiEndPoint: String?,
        httpMethod: String?,
        accessToken: String? = "",
        payload: JSON? = nil,
        expect: T.Type,
        completionHandler: @escaping DataCompletionBlock
    ) {
        let url = APIEndpoints.baseURL + (apiEndPoint ?? "")

        // Perform the API request
        URLSession.shared.request(url: URL(string: url),
                                  httpMethod: httpMethod,
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
}
