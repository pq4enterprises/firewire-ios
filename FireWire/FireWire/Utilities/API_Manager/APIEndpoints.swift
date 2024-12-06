//
//  APIEndpoints.swift
//  JP_apiSample
//
//  Created by prithviraj on 19/10/22.
//

import Foundation

enum APIEndpoints {
    static let baseURL = "https://firewire-api.atomgroups.com/"
    static let login = "api/app/auth/login"
     static let register = "api/app/auth/register"
    static let incidentList = "/api/admin/incident"
}

enum APIPayload {
    case login(email: String, password: String)

    func toDictionary() -> [String: Any] {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
        }
    }
}
