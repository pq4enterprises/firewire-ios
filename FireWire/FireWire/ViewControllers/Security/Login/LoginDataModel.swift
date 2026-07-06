//
//  LoginDataModel.swift
//  FireWire
//
//

import UIKit

struct LoginApiResponse: Codable {
    let message: String
    let code: String
    let data: LoginDataModel?
}

struct LoginDataModel: Codable {
    let id: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let mobile: String?
    let role: String?
    let verified: Bool?
    let active: Bool?
    let token: String?
    let refreshToken: String?
    let emailVerified: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case email
        case mobile
        case role
        case verified
        case active
        case token
        case refreshToken
        case emailVerified
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        mobile = try container.decodeIfPresent(String.self, forKey: .mobile)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        verified = (try? container.decodeIfPresent(Bool.self, forKey: .verified)) ?? false
        active = try container.decodeIfPresent(Bool.self, forKey: .active)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        emailVerified = (try? container.decodeIfPresent(Bool.self, forKey: .emailVerified)) ?? false
    }
}
