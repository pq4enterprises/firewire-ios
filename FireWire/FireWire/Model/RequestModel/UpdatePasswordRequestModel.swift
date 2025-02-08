//
//  UpdatePasswordRequestModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 08/02/25.
//

struct UpdatePasswordRequestModel {
    public var oldPassword: String
    public var newPassword: String
    public var confirmPassword: String

    public init(oldPassword: String, newPassword: String, confirmPassword: String) {
        self.oldPassword = oldPassword
        self.newPassword = newPassword
        self.confirmPassword = confirmPassword
    }
}
