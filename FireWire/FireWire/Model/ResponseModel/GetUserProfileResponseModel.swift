//
//  GetUserProfileResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 31/01/25.
//

struct GetUserProfileResponseModel: Codable {
    let message: String
    let code: String
    let data: UserProfileData?
}

struct UserProfileData: Codable {
    let id: String
    let firstName: String
    let lastName: String?
    let mobile: String
    let email: String
    let role: String
    let title: String
    let locality, subLocality: [String]?
    let v: Int?
    let refreshToken, webToken, lastLogin: String?
    let resetToken: String?
    let permission: [String]?
    let type: String?
    let img: String?
    let phone: Int?
    let otpValidUpto: String?
    let unit: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName, mobile, email, role, title, locality, subLocality
        case v = "__v"
        case refreshToken, webToken, lastLogin, resetToken, permission, type, img, lastName, phone, otpValidUpto, unit
    }
}
