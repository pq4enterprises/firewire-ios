//
//  ForgotPasswordResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import Foundation

struct ForgotPasswordResponseModel: Codable {
    let message, code: String
    let data: ForgotPasswordResponseData?
}

struct ForgotPasswordResponseData: Codable {
    let error: Bool
    let message: String

    enum CodingKeys: String, CodingKey {
        case error, message
    }
}
