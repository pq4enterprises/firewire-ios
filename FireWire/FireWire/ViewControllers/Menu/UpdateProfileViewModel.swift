//
//  UpdateProfileViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 23/12/24.
//

import Foundation

final class UpdateProfileViewModel {
    public var delegate: UpdateProfileViewDelegate?

    func getUserProfile() {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.userProfile,
            expect: GetUserProfileResponseModel.self,
            requestType: APIConstants.GET
        ) { [weak self] response, _, _ in
            guard let apiResponse = response as? GetUserProfileResponseModel else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self?.delegate?.error(message: errorMessage)
                return
            }

            if apiResponse.code != "success" {
                self?.delegate?.error(message: apiResponse.message)
                return
            }

            guard let userData = apiResponse.data else {
                self?.delegate?.error(message: "Missing user data")
                return
            }

            self?.delegate?.dataLoaded(userData)
        }
    }

    func updateUserProfile(_ requestModel: UpdateProfileRequestModel) {
        let updateUserRequestModel = APIPayload.updateUserProfile(requestModel).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.userProfile,
            payload: updateUserRequestModel as JSON,
            expect: SuccessResponseModel.self,
            requestType: APIConstants.PUT
        ) { [weak self] response, _, _ in
            guard let apiResponse = response else {
                self?.delegate?.profileUpdated("Profile update failed, try again after sometime")
                return
            }

            if apiResponse is SuccessResponseModel {
                self?.delegate?.profileUpdated("Profile Updated")
            } else {
                self?.delegate?.profileUpdated("Profile update failed, try again after sometime")
            }
        }
    }

    func validate(_ model: UpdateProfileRequestModel) -> ValidationError {
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

        return .success
    }
}
