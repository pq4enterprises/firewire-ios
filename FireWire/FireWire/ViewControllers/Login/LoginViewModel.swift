//
//  LoginViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/12/24.
//

import Foundation

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

            UserDefaults.standard.set(loginData.id, forKey: "user_id")
            UserDefaults.standard.set(loginData.firstName, forKey: "name")
            UserDefaults.standard.set(loginData.email, forKey: "email")
            UserDefaults.standard.set(loginData.token ?? "", forKey: "token")
            UserDefaults.standard.synchronize()

            self?.delegate?.loginSuccess()
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

            guard let apiResponse = response else {
                return
            }

            if let loginDataResponse = apiResponse as? LoginApiResponse, let loginData = loginDataResponse.data {
                debugPrint(loginDataResponse)
                UserDefaults.standard.set(loginData.id, forKey: "user_id")
                UserDefaults.standard.set(loginData.firstName, forKey: "name")
                UserDefaults.standard.set(loginData.email, forKey: "email")
                UserDefaults.standard.set(loginData.token ?? "", forKey: "token")
                UserDefaults.standard.synchronize()

                self?.delegate?.loginSuccess()
            } else {
                print("Invalid response object")
            }
        }
    }
}
