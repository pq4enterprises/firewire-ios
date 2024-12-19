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
            guard let apiResponse = response else {
                return
            }

            if let loginDataResponse = apiResponse as? LoginApiResponse {
                debugPrint(loginDataResponse)
                UserDefaults.standard.set(loginDataResponse.data.firstName, forKey: "name")
                UserDefaults.standard.set(loginDataResponse.data.email, forKey: "email")
                UserDefaults.standard.set(loginDataResponse.data.token ?? "", forKey: "token")
                UserDefaults.standard.synchronize()

                self?.delegate?.loginSuccess()
            } else {
                self?.delegate?.loginFailed(errorMessage: "Invalid response")
            }
        }
    }

    // TODO: API response need to handled, currently API throwing error
    func authenticateSocialLogin(_ requestModel: SocialLoginRequestModel) {
        let loginRequestModel = APIPayload.socialLogin(
            token: requestModel.token,
            socialType: requestModel.socialType,
            role: requestModel.role
        ).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.socialLogin,
            payload: loginRequestModel as JSON,
            expect: LoginApiResponse.self
        ) { response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if let loginDataResponse = apiResponse as? LoginApiResponse {
                debugPrint(loginDataResponse)
            } else {
                print("Invalid response object")
            }
        }
    }
}
