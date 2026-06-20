//
//  VerifyEmailResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/06/26.
//

import Foundation

struct VerifyEmailResponseModel: Codable {
    let message, code: String
    let data: VerifyEmailResponseData?
}

struct VerifyEmailResponseData: Codable {
    let id: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let mobile: String?
    let role: String?
    let verified: Bool?
    let emailVerified: Bool?
    let active: Bool?
    let token: String?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case email
        case mobile
        case role
        case verified
        case emailVerified
        case active
        case token
        case refreshToken
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        email = try container.decode(String.self, forKey: .email)
        mobile = try container.decode(String.self, forKey: .mobile)
        role = try container.decode(String.self, forKey: .role)
        verified = (try? container.decodeIfPresent(Bool.self, forKey: .verified)) ?? false
        emailVerified = (try? container.decodeIfPresent(Bool.self, forKey: .emailVerified)) ?? false
        active = try container.decode(Bool.self, forKey: .active)
        token = try container.decode(String.self, forKey: .token)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
    }
}
