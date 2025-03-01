//
//  LoginViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/12/24.
//

import Foundation
import OneSignalFramework

final class LoginViewModel {
    weak var delegate: LoginViewDelegate?

    func performUserLogin(_ requestModel: LoginRequestModel) {
        let loginRequestModel = APIPayload.login(email: requestModel.email, password: requestModel.password).toDictionary()

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

            if let userId = loginData.id {
                OneSignal.login(userId)
            }

            UserDefaults.standard.set(loginData.id, forKey: "user_id")
            let userName = "\(loginData.firstName ?? "") \(loginData.lastName ?? "")"
            UserDefaults.standard.set(userName, forKey: "name")
            UserDefaults.standard.set(loginData.email, forKey: "email")
            UserDefaults.standard.set(loginData.token ?? "", forKey: "token")
            UserDefaults.standard.synchronize()

            self?.getUserProfile()
            self?.delegate?.loginSuccess(.general)
        }
    }

    func getUserProfile() {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.userProfile,
            expect: GetUserProfileResponseModel.self,
            requestType: APIConstants.GET
        ) { response, _, _ in
            if let apiResponse = response as? GetUserProfileResponseModel, let userData = apiResponse.data {
                if let profileImage = userData.img {
                    UserDefaults.standard.set(profileImage, forKey: "profile_image")
                }
            }
        }
    }

    // TODO: API response need to handled, currently API throwing error
    func authenticateSocialLogin(_ requestModel: SocialLoginRequestModel) {
        let loginRequestModel = APIPayload.socialLogin(
            token: requestModel.token,
            socialType: requestModel.socialType.rawValue,
            role: requestModel.role
        ).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.socialLogin,
            payload: loginRequestModel as JSON,
            expect: LoginApiResponse.self
        ) { [weak self] response, _, _ in

            guard let loginDataResponse = response as? LoginApiResponse else {
                let errorMessage = (response == nil) ? "Invalid request" : "Unexpected response format"
                self?.delegate?.loginFailed(errorMessage: errorMessage)
                return
            }
            
            if loginDataResponse.code.lowercased() != "success"{
                self?.delegate?.loginFailed(errorMessage: loginDataResponse.message)
                return
            }
            
            guard let loginData = loginDataResponse.data else {
                self?.delegate?.loginFailed(errorMessage: "Missing login data")
                return
            }
            
            UserDefaults.standard.set(loginData.id, forKey: "user_id")
            let userName = "\(loginData.firstName ?? "") \(loginData.lastName ?? "")"
            UserDefaults.standard.set(userName, forKey: "name")
            UserDefaults.standard.set(loginData.email, forKey: "email")
            UserDefaults.standard.set(loginData.token ?? "", forKey: "token")
            UserDefaults.standard.synchronize()
           
            let type: LoginType = requestModel.socialType == .google ? .google : .facebook
            self?.delegate?.loginSuccess(type)
            
        }
    }

    func validate(email: String, password: String) -> ValidationError {
        if !email.isValidEmail() {
            return .failure(message: "Enter a valid email")
        }

        if password.count < 8 {
            return .failure(message: "Invalid password")
        }

        return .success
    }
}
