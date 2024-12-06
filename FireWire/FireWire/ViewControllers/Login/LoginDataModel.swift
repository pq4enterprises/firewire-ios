//
//  LoginDataModel.swift
//  FireWire
//
//  Created by JoPrithiviraj on 26/11/24.
//

import UIKit

struct LoginApiResponse: Codable {
    let message: String
    let code: String
    let data: LoginDataModel
}

struct LoginDataModel: Codable {
    let id: String?
    let firstName: String?
    let email: String?
    let mobile: String?
    let role: String?
    let verified: Bool?
    let active: Bool?
    let token: String?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case email
        case mobile
        case role
        case verified
        case active
        case token
        case refreshToken
    }
}
