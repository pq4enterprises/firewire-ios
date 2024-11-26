//
//  APIRequest.swift
//  JP_apiSample
//
//  Created by prithviraj on 19/10/22.
//

import UIKit
typealias JSON = [String: Any]

public class APIRequest {
    typealias DataCompletionBlock = (_ response : Any? ,_ statusCode:Int? , _ error:String?) -> (Void)
    
    func callLoginApi<T:Codable>( apiEndPoint: String?, headers:[String:String], httpMethod:String?, Accesstoken: String?, payload: JSON? = nil, expect: T.Type, completionHandler: @escaping DataCompletionBlock) {
        let url = APIEndpoints.baseURL + (apiEndPoint ?? "")
        URLSession.shared.request(url: URL(string: url), httpMethod: httpMethod, authTokenString: Accesstoken ?? "", headers: headers, payload: payload, expecting: expect.self) { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    completionHandler(response, nil, nil)
                }
            case .failure(let error):
                completionHandler(nil, nil, error.localizedDescription)
            }
        }
    }
    
    func callFetchTenants<T:Codable>( apiEndPoint: String?, headers:[String:String], httpMethod:String?, Accesstoken: String?, payload: JSON? = nil, expect: T.Type, completionHandler: @escaping DataCompletionBlock) {
        let url = APIEndpoints.baseURL + (apiEndPoint ?? "")
        URLSession.shared.request(url: URL(string: url), httpMethod: httpMethod, authTokenString: Accesstoken ?? "", headers: headers, payload: payload, expecting: expect.self) { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    completionHandler(response, nil, nil)
                }
            case .failure(let error):
                completionHandler(nil, nil, error.localizedDescription)
            }
        }
    }
    
    func callFetchUserData<T:Codable>( apiEndPoint: String?, headers:[String:String], httpMethod:String?, Accesstoken: String?, payload: JSON? = nil, expect: T.Type, completionHandler: @escaping DataCompletionBlock) {
        let url = APIEndpoints.baseURL + (apiEndPoint ?? "")
        URLSession.shared.request(url: URL(string: url), httpMethod: httpMethod, authTokenString: Accesstoken ?? "", headers: headers, payload: payload, expecting: expect.self) { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    completionHandler(response, nil, nil)
                }
            case .failure(let error):
                completionHandler(nil, nil, error.localizedDescription)
            }
        }
    }
    
    func callModuleCounts<T:Codable>( apiEndPoint: String?, headers:[String:String], httpMethod:String?, Accesstoken: String?, payload: JSON? = nil, expect: T.Type, completionHandler: @escaping DataCompletionBlock) {
        let url = APIEndpoints.baseURL + (apiEndPoint ?? "")
        URLSession.shared.request(url: URL(string: url), httpMethod: httpMethod, authTokenString: Accesstoken ?? "", headers: headers, payload: payload, expecting: expect.self) { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    completionHandler(response, nil, nil)
                }
            case .failure(let error):
                completionHandler(nil, nil, error.localizedDescription)
            }
        }
    }
}

