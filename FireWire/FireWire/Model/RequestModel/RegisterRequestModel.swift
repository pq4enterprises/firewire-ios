//
//  RegisterRequestModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 12/12/24.
//

import Foundation

struct RegisterRequestModel {
    public var firstName: String
    public var lastName: String
    public var email: String
    public var mobile: String
    public var password: String
    public var confirmPassword: String
    public var title: String

    public init(firstName: String, lastName: String, email: String, mobile: String, password: String, confirmPassword: String, title: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.mobile = mobile
        self.password = password
        self.confirmPassword = confirmPassword
        self.title = title
    }
}
