//
//  APIEndpoints.swift
//  JP_apiSample
//
//  Created by prithviraj on 19/10/22.
//

import Foundation
import UIKit

enum APIEndpoints {
    #if DEV
        static let baseURL = "https://dev-firewire-api.atomgroups.work/"
    #else
        static let baseURL = "https://firewire-api.atomgroups.work/"
    #endif

    static let register = "api/app/auth/register"
    static let login = "api/app/auth/login"
    static let forgotPassword = "api/app/auth/forgot-password"
    static let verifyOtp = "api/app/auth/otp-verify"
    static let resetPassword = "api/app/auth/reset-password"
    static let socialLogin = "api/app/auth/social-login"
    static let incidentList = "api/app/incident"
    static let incidentDetail = "api/app/incident/%@"
    static let localityList = "api/app/locality"
    static let favIncident = "api/app/incident/activity"
    static let userProfile = "api/app/user/profile"
    static let commentsList = "api/app/incident/comment/%@"
    static let addComment = "api/app/incident/activity"
    static let uploadImage = "api/common/upload"
    static let feedList = "api/app/feed"
    static let deleteAccount = "api/app/user/profile"
    static let updatePassword = "api/app/auth/update-password"
    static let setSelectedArea = "api/app/user/area"
    static let setNotificationArea = "api/app/user/notification"

    static let newsList = "https://nycfirewire.net/feed"
    static let submitTipUrl = "https://nycfirewire.net/send-a-tip/"
    static let chicagoPodcastUrl = "https://www.chicagosbraveststories.com"
    static let contactUrl = "https://nycfirewire.net/contact/"
    static let fireWireUrl = "https://nycfirewire.net/"
    static let saltyWireUrl = "https://saltywire.com/"
    static let termsAndConditionUrl = "https://nycfirewire.net/terms"
    static let privacyPolicyUrl = "https://nycfirewire.net/privacy"
}

enum SocialLoginType: String{
    case google = "google"
    case facebook = "facebook"
}

enum APIPayload {
    case login(email: String, password: String)
    case socialLogin(token: String, socialType: String, role: String)
    case forgotPassword(email: String)
    case verifyOtp(email: String, otp: String)
    case resetPassword(resetToken: String, password: String, confirmPassword: String)
    case favouriteIncident(userId: String, incidentId: String, type: String)
    case updateUserProfile(_ model: UpdateProfileRequestModel)
    case incidentList(_ model: IncidentRequestModel)
    case incidentLocalityList(_ model: IncidentLocalityRequestModel)
    case addComment(_ model: AddCommentRequestModel)
    case commentsList(_ model: CommonRequestModel)
    case feedList(_ model: CommonRequestModel)
    case postReasonToAccountDelete(reason: String)
    case deleteAccount
    case updatePassword(_ model: UpdatePasswordRequestModel)

    func toDictionary() -> [String: Any] {
        switch self {
        case let .login(email, password):
            return ["email": email, "password": password]
        case let .socialLogin(token, socialType, role):
            return ["token": token, "socialType": socialType, "role": role]
        case let .forgotPassword(email):
            return ["email": email]
        case let .verifyOtp(email, otp):
            return ["email": email, "otp": otp]
        case let .resetPassword(resetToken, password, confirmPassword):
            return ["resetToken": resetToken, "password": password, "confirmPassword": confirmPassword]
        case let .favouriteIncident(userId, incidentId, type):
            return ["userId": userId, "incidentId": incidentId, "type": type]
        case let .updateUserProfile(model):
            return [
                "firstName": model.firstName,
                "lastName": model.lastName,
                "email": model.email,
                "mobile": model.mobile,
                "title": model.title,
                "img": model.img
            ]
        case let .incidentList(model):
            var dictionary: [String: Any] = [
                "sortBy": model.sortBy,
                "sortDir": model.sortDir,
                "offset": model.offset,
                "limit": model.limit
            ]

            if let query = model.query {
                if let queryJsonString = query.toJsonString() {
                    dictionary["query"] = queryJsonString
                }
            }

            return dictionary
        case let .incidentLocalityList(model):
            return [
                "sortBy": model.sortBy,
                "sortDir": model.sortDir,
                "offset": model.offset,
                "limit": model.limit,
                "query": model.listType?.toJsonString() ?? ""
            ]
        case let .addComment(model):
            return [
                "userId": model.userId,
                "incidentId": model.incidentId,
                "type": model.type,
                "comment": model.comment,
                "img": model.img
            ]
        case let .commentsList(model):
            return [
                "sortBy": model.sortBy,
                "sortDir": model.sortDir,
                "offset": model.offset,
                "limit": model.limit
            ]
        case let .feedList(model):
            return [
                "sortBy": model.sortBy,
                "sortDir": model.sortDir,
                "offset": model.offset,
                "limit": model.limit
            ]
        case let .postReasonToAccountDelete(reason):
            return [
                "text": reason
            ]
        case .deleteAccount:
            return [
                "deleted": true
            ]
        case let .updatePassword(model):
            return [
                "oldPassword": model.oldPassword,
                "newPassword": model.newPassword,
                "confirmPassword": model.confirmPassword
            ]
        }
    }
}
