//
//  SocialLoginRequestModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/12/24.
//

import Foundation

struct SocialLoginRequestModel {
    public var token: String
    public var socialType: SocialLoginType
    public var role: String

    public init(token: String, socialType: SocialLoginType, role: String) {
        self.token = token
        self.socialType = socialType
        self.role = role
    }
}
