//
//  RegisterResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 12/12/24.
//

import Foundation

struct RegisterResponseModel: Codable {
    let message: String?
    let code: String?
    let error: String?
    let data: RegisterResponseData?
}

struct RegisterResponseData: Codable {
    let email: String
    let emailVerified: Bool

    enum CodingKeys: String, CodingKey {
        case email, emailVerified
    }
}
