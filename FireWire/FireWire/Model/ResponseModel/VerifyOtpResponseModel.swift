//
//  VerifyOtpResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import Foundation

struct VerifyOtpResponseModel: Codable {
    let message, code: String
    let data: VerifyOtpResponseData?
}

struct VerifyOtpResponseData: Codable {
    let resetToken: String
}
