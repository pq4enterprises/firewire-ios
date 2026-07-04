//
//  ResendOTPForEmailResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 04/07/26.
//

import Foundation

struct ResendOTPForEmailResponseModel: Codable {
    var message: String = ""
    var code: String = ""
    let data: ResendEmailOTPData?

    enum CodingKeys: String, CodingKey {
        case message
        case code
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        code = try container.decodeIfPresent(String.self, forKey: .code) ?? ""
        data = try container.decodeIfPresent(ResendEmailOTPData.self, forKey: .data)

    }
}

struct ResendEmailOTPData: Codable {
    let email: String
    let emailVerified: Bool
}
