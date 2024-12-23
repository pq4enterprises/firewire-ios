//
//  UpdateProfileRequestModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/12/24.
//

import Foundation

struct UpdateProfileRequestModel {
    public var firstName: String
    public var lastName: String
    public var email: String
    public var mobile: String
    public var title: String

    public init(
        firstName: String,
        lastName: String,
        email: String,
        mobile: String,
        title: String
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.mobile = mobile
        self.title = title
    }
}
