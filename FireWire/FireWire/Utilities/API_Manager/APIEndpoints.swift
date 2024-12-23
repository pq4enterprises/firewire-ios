//
//  APIEndpoints.swift
//  JP_apiSample
//
//  Created by prithviraj on 19/10/22.
//

import Foundation

enum APIEndpoints {
    static let baseURL = "https://dev-firewire-api.atomgroups.work/"

    static let register = "api/app/auth/register"
    static let login = "api/app/auth/login"
    static let socialLogin = "api/app/auth/social-login"
    static let incidentList = "api/app/incident"
    static let incidentDetail = "api/app/incident/%@"
    static let localityList = "api/app/locality"
    static let favIncident = "api/app/incident/activity"

    static let newsList = "https://nycfirewire.net/feed"
    static let submitTipUrl = "https://nycfirewire.net/send-a-tip/"
    static let chicagoPodcastUrl = "https://www.chicagosbraveststories.com"
    static let contactUrl = "https://nycfirewire.net/contact/"
    static let fireWireUrl = "https://nycfirewire.net/"
    static let saltyWireUrl = "https://saltywire.com/"
}

enum SocialLoginType: String{
    case google = "google"
    case facebook = "facebook"
}

enum APIPayload {
    case login(email: String, password: String)
    case socialLogin(token: String, socialType: SocialLoginType, role: String)
    case favouriteIncident(userId: String, incidentId: String, type: String)

    func toDictionary() -> [String: Any] {
        switch self {
        case let .login(email, password):
            return ["email": email, "password": password]
        case let .socialLogin(token, socialType, role):
            return ["token": token, "socialType": socialType, "role": role]
        case let .favouriteIncident(userId, incidentId, type):
            return ["userId": userId, "incidentId": incidentId, "type": type]
        }
    }
}
