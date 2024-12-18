//
//  APIEndpoints.swift
//  JP_apiSample
//
//  Created by prithviraj on 19/10/22.
//

import Foundation

enum APIEndpoints {
    static let baseURL = "https://firewire-api.atomgroups.com/"

    static let register = "api/app/auth/register"
    static let login = "api/app/auth/login"
    static let incidentList = "/api/app/incident"
    static let incidentDetail = "/api/app/incident/%@"
    static let localityList = "/api/app/locality"

    static let newsList = "https://nycfirewire.net/feed"
    static let submitTipUrl = "https://nycfirewire.net/send-a-tip/"
    static let chicagoPodcastUrl = "https://www.chicagosbraveststories.com"
    static let contactUrl = "https://nycfirewire.net/contact/"
    static let fireWireUrl = "https://nycfirewire.net/"
    static let saltyWireUrl = "https://saltywire.com/"
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
