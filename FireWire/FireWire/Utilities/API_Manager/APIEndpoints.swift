//
//  APIEndpoints.swift
//  JP_apiSample
//
//  Created by prithviraj on 19/10/22.
//

import Foundation
import UIKit

enum APIEndpoints {
    static let baseURL = "https://api.nycfirewireapp.com/"
    //static let baseURL = "https://staging.api.nycfirewireapp.com/"

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
    static let deleteComment = "api/app/comment/%@"
    static let reportComment = "api/app/incident/comment/report/%@"
    static let setFeaturedImage = "api/app/incident/%@"
    static let uploadImage = "api/common/upload"
    static let feedList = "api/app/feed"
    static let deleteAccount = "api/app/user/profile"
    static let updatePassword = "api/app/auth/update-password"
    static let setSelectedArea = "api/app/user/area"
    static let setNotificationArea = "api/app/user/notification"
    static let submitSubscriptionDetails = "api/app/payment"
    static let refreshToken = "api/app/auth/token/refresh"
    static let appLinks = "api/app/link"

    static let newsList = "https://nycfirewire.net/feed"
    static let submitTipUrl = "https://nycfirewire.net/send-a-tip/"
    static let chicagoPodcastUrl = "https://www.chicagosbraveststories.com"
    static let contactUrl = "https://nycfirewire.net/contact/"
    static let fireWireUrl = "https://nycfirewire.net/"
    static let fireWireNewsUrl = "https://nycfirewire.net/news/"
    static let termsAndConditionUrl = "https://nycfirewire.net/terms"
    static let privacyPolicyUrl = "https://nycfirewire.net/privacy"

    static let postAdminUrl = "https://admin.nycfirewireapp.com/noauth/create/incident?form=add&token=%@&theme=%@"
}

enum SocialLoginType: String {
    case google
    case facebook
    case apple
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
    case submitSubscriptionDetails(_ model: SubmitSubscriptionModel)
    case reportComment(userId: String)
    case setFeaturedImage(imageUrl: String, commentId: String)
    case refreshToken(refreshToken: String)

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
            // Filter / area-selection screens. The server marks each locality and
            // subLocality with the caller's own isChecked from their stored UserLocality
            // rows, so the saved selection comes back with the list — no local cache needed.
            //
            // show=true is required: without it the server falls back to `limit || 10` and
            // returns only the FIRST TEN localities. Any saved selection outside that page
            // was simply absent from the screen, which is what made filters look like they
            // never persisted. With show=true the server drops its $skip/$limit stages, so
            // offset/limit are meaningless here and are not sent. Matches Android f9cd91a.
            return [
                "sortBy": model.sortBy,
                "sortDir": model.sortDir,
                "show": true,
                "query": model.listType?.toJsonString() ?? ""
            ]
        case let .addComment(model):
            var dictionary: [String: Any] = [
                "userId": model.userId,
                "incidentId": model.incidentId,
                "type": model.type,
                "comment": model.comment,
                "img": model.img
            ]

            if let parentId = model.parentId {
                dictionary["parentId"] = parentId
            }

            if !model.mentions.isEmpty {
                dictionary["mentions"] = model.mentions
            }

            return dictionary
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
        case let .submitSubscriptionDetails(model):
            return [
                "userId": model.userId,
                "paymentMethod": model.paymentMethod,
                "paymentToken": model.paymentToken,
                "transactionId": model.transactionId,
                "amount": model.amount,
                "currency": model.currency,
                "status": model.status,
                "purchaseDate": model.purchaseDate,
                "expiredDate": model.expiredDate,
                "type": model.type
            ]
        case let .reportComment(userId):
            return [
                "userId": userId
            ]
        case let .setFeaturedImage(imageUrl, commentId):
            return [
                "featuredImageUrl": imageUrl,
                "commentId": commentId
            ]
        case let .refreshToken(refreshToken):
            return [
                "refreshToken": refreshToken
            ]
        }
    }
}
