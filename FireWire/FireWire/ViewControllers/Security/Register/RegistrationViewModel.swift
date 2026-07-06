//
//  RegistrationViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 12/12/24.
//

import Foundation
import OneSignalFramework

enum ValidationError: Error {
    case success
    case failure(message: String)
}

final class RegistrationViewModel {
    var delegate: RegistrationViewModelDelegate?

    init(delegate: RegistrationViewModelDelegate?) {
        self.delegate = delegate
    }

    public func registerNewUser(_ model: RegisterRequestModel) {
        let parameters: [String: Any] = [
            "firstName": model.firstName,
            "lastName": model.lastName,
            "email": model.email,
            "mobile": model.mobile,
            "password": model.password,
            "title": model.title
        ]

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.register,
            payload: parameters as JSON,
            expect: RegisterResponseModel.self)
        { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.registrationFail(errorMessage: errorMessage)
                return
            }

            guard let registerResponse = response as? RegisterResponseModel else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self?.delegate?.registrationFail(errorMessage: errorMessage)
                return
            }

            if registerResponse.code == "email_not_verified" {
                self?.delegate?.registrationSuccess(forEmail: model.email)
            } else {
                let errorMessage = registerResponse.message ?? registerResponse.error ?? "Error registering new user"
                self?.delegate?.registrationFail(errorMessage: errorMessage)
            }
        }
    }

    /*func performLogin(_ model: RegisterRequestModel){
        let loginRequestModel = APIPayload.login(email: model.email, password: model.password).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.login,
            payload: loginRequestModel as JSON,
            expect: LoginApiResponse.self
        ) { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.loginFailed(errorMessage: errorMessage)
                return
            }

            guard let apiResponse = response as? LoginApiResponse else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self?.delegate?.loginFailed(errorMessage: errorMessage)
                return
            }

            if apiResponse.code != "success" {
                self?.delegate?.loginFailed(errorMessage: apiResponse.message)
                return
            }

            guard let loginData = apiResponse.data else {
                self?.delegate?.loginFailed(errorMessage: "Missing login data")
                return
            }

            if let userId = loginData.id {
                OneSignal.login(userId)
            }

            FWUserDefaults.setStringForKey(key: .userIDKey, value: loginData.id)
            let userName = "\(loginData.firstName ?? "") \(loginData.lastName ?? "")"
            FWUserDefaults.setStringForKey(key: .userNameKey, value: userName)
            FWUserDefaults.setStringForKey(key: .userEmailKey, value: loginData.email)
            FWUserDefaults.setStringForKey(key: .userTokenKey, value: loginData.token)
            FWUserDefaults.setStringForKey(key: .refreshTokenKey, value: loginData.refreshToken)
            FWUserDefaults.setStringForKey(key: .userRoleKey, value: loginData.role)

            self?.delegate?.loginSuccess()
        }
    }*/

    func validate(_ model: RegisterRequestModel) -> ValidationError {
        if model.firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            return .failure(message: "First Name is required")
        }

        if model.lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            return .failure(message: "Last Name is required")
        }

        if model.email.isEmpty {
            return .failure(message: "Email is required")
        }

        if !model.email.isValidEmail() {
            return .failure(message: "Enter a valid email")
        }

        if model.mobile.isEmpty {
            return .failure(message: "Phone number is required")
        }

        if model.mobile.count < 10 {
            return .failure(message: "Enter a valid phone number")
        }

        if model.title.trimmingCharacters(in: .whitespaces).isEmpty {
            return .failure(message: "Title is required")
        }

        if model.password.isEmpty {
            return .failure(message: "Password is required")
        }

        if model.password.count < 8 {
            return .failure(message: "Password should be at least 8 character long")
        }

        if model.confirmPassword.isEmpty {
            return .failure(message: "Please confirm password")
        }

        if model.password != model.confirmPassword {
            return .failure(message: "One of the password is not matching")
        }

        return .success
    }
}
