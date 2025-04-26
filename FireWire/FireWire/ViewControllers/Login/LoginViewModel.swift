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
            FWUserDefaults.setStringForKey(key: .userRoleKey, value: loginData.role)

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
                    FWUserDefaults.setStringForKey(key: .userImageKey, value: profileImage)
                }
            }
        }
    }

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
        ) { [weak self] response, _, error in

            if let errorMessage = error {
                self?.delegate?.loginFailed(errorMessage: errorMessage)
                return
            }

            guard let loginDataResponse = response as? LoginApiResponse else {
                let errorMessage = (response == nil) ? "Invalid request" : "Unexpected response format"
                self?.delegate?.loginFailed(errorMessage: errorMessage)
                return
            }

            if loginDataResponse.code.lowercased() != "success" {
                self?.delegate?.loginFailed(errorMessage: loginDataResponse.message)
                return
            }

            guard let loginData = loginDataResponse.data else {
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
            FWUserDefaults.setStringForKey(key: .userRoleKey, value: loginData.role)

            self?.getUserProfile()
            let type: LoginType = requestModel.socialType == .google ? .google : .apple
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

    func validateIfAreaSelected(forType type: LocalityListType, completion: @escaping (Bool) -> Void) {
        var requestModel = IncidentLocalityRequestModel(sortBy: "createdAt", sortDir: "desc", offset: 1, limit: 10)
        requestModel.listType = ListType(type: type.rawValue)

        let getIncidentLocalityRequestModel = APIPayload.incidentLocalityList(requestModel).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.localityList,
            payload: getIncidentLocalityRequestModel,
            expect: LocalityResponseModel.self,
            requestType: APIConstants.GET
        ) { response, _, _ in

            guard let localityResponse = response as? LocalityResponseModel,
                  let localityData = localityResponse.data
            else {
                completion(false)
                return
            }

            let isAnyAreaSelected = localityData.data.contains { locality in
                locality.subLocality.contains { $0.isChecked } ||
                (locality.unit?.compactMap { $0?.isChecked }.contains(true) ?? false) ||
                (locality.incidentType?.compactMap { $0?.isChecked }.contains(true) ?? false)
            }
            completion(isAnyAreaSelected)
        }
    }
}
