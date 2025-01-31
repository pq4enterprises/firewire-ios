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
    var delegate: RegistrationViewModelDelegate?

    init(delegate: RegistrationViewModelDelegate?) {
        self.delegate = delegate
    }

    public func registerNewUser(_ model: RegisterRequestModel) {
        let parameters: [String: Any] = [
            "firstName": model.firstName,
            "email": model.email,
            "mobile": model.mobile,
            "password": model.password,
            "title": model.title
        ]

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.register,
            payload: parameters as JSON,
            expect: RegisterResponseModel.self)
        { [weak self] response, _, _ in
            guard let registerResponse = response as? RegisterResponseModel else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self?.delegate?.registrationFail(errorMessage: errorMessage)
                return
            }

            if registerResponse.code != "success" {
                self?.delegate?.registrationFail(errorMessage: registerResponse.message ?? "Error registering new user")
                return
            }else{
                self?.performLogin(model) // Perform automatic login after successful registration
            }



//            if registerResponse.error != nil {
//                self?.delegate?.registrationFail(errorMessage: registerResponse.error ?? "Error registering new user")
//            } else {
//                if registerResponse.message?.lowercased() == "success" {
//                    self?.performLogin(model) // Perform automatic login after successful registration
//                } else {
//                    self?.delegate?.registrationFail(errorMessage: "Error registering new user")
//                }
//            }
        }
    }

    func performLogin(_ model: RegisterRequestModel){
        let loginRequestModel = APIPayload.login(email: model.email, password: model.password).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.login,
            payload: loginRequestModel as JSON,
            expect: LoginApiResponse.self
        ) { [weak self] response, _, _ in
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

            UserDefaults.standard.set(loginData.id, forKey: "user_id")
            UserDefaults.standard.set(loginData.firstName, forKey: "name")
            UserDefaults.standard.set(loginData.email, forKey: "email")
            UserDefaults.standard.set(loginData.token ?? "", forKey: "token")
            UserDefaults.standard.synchronize()

            self?.delegate?.loginSuccess()
        }
    }

    func validate(_ model: RegisterRequestModel) -> ValidationError {
        if model.firstName.isEmpty {
            return .failure(message: "First name is required")
        }

        if model.email.isEmpty {
            return .failure(message: "Email is required")
        }

        if model.mobile.isEmpty {
            return .failure(message: "Phone number is required")
        }

        if model.title.isEmpty {
            return .failure(message: "Title is required")
        }

        if model.password.isEmpty {
            return .failure(message: "Password is required")
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
