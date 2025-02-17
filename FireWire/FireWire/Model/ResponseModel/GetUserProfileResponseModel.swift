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
    let mobile: String?
    let email: String?
    let role: String?
    let title: String?
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
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        mobile = try container.decodeIfPresent(String.self, forKey: .mobile)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        locality = try container.decodeIfPresent([String].self, forKey: .locality)
        subLocality = try container.decodeIfPresent([String].self, forKey: .subLocality)
        v = try container.decodeIfPresent(Int.self, forKey: .v)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        webToken = try container.decodeIfPresent(String.self, forKey: .webToken)
        lastLogin = try container.decodeIfPresent(String.self, forKey: .lastLogin)
        resetToken = try container.decodeIfPresent(String.self, forKey: .resetToken)
        permission = try container.decodeIfPresent([String].self, forKey: .permission)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        img = try container.decodeIfPresent(String.self, forKey: .img)
        phone = try container.decodeIfPresent(Int.self, forKey: .phone)
        otpValidUpto = try container.decodeIfPresent(String.self, forKey: .otpValidUpto)
        unit = try container.decodeIfPresent([String].self, forKey: .unit)
    }
}
