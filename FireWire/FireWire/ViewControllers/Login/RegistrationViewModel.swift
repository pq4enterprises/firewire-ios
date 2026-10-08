//
//  RegistrationViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 12/12/24.
//

import Foundation

enum ValidationError: Error {
    case success
    case failure(message: String)
}

final class RegistrationViewModel {
    weak var delegate: RegistrationViewModelDelegate?

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

            // The server emails a 6-digit code on every successful registration and
            // also when an unverified address registers again ("email_not_verified").
            // Either way the next step is the verification screen, as on Android.
            if registerResponse.code == "success" || registerResponse.code == "email_not_verified" {
                self?.delegate?.registrationSuccess(email: model.email.lowercased())
            } else {
                let errorMessage = registerResponse.message ?? registerResponse.error ?? "Error registering new user"
                self?.delegate?.registrationFail(errorMessage: errorMessage)
            }
        }
    }

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
