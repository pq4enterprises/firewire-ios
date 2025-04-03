//
//  UpdateProfileViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 23/12/24.
//

import Foundation
import UIKit

final class UpdateProfileViewModel {
    public var delegate: UpdateProfileViewDelegate?

    func getUserProfile() {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.userProfile,
            expect: GetUserProfileResponseModel.self,
            requestType: APIConstants.GET
        ) { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.error(message: errorMessage)
                return
            }

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

            let userName = "\(userData.firstName) \(userData.lastName ?? "")"
            FWUserDefaults.setStringForKey(key: .userNameKey, value: userName)
            FWUserDefaults.setStringForKey(key: .userEmailKey, value: userData.email)

            if let profileImage = userData.img {
                FWUserDefaults.setStringForKey(key: .userImageKey, value: profileImage)
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
        ) { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.error(message: errorMessage)
                return
            }

            guard let apiResponse = response else {
                self?.delegate?.profileUpdated("Profile update failed, try again after sometime")
                return
            }

            if apiResponse is SuccessResponseModel {
                self?.getUserProfileAndUpdateLocalStorage()
                self?.delegate?.profileUpdated("Profile Updated")
            } else {
                self?.delegate?.profileUpdated("Profile update failed, try again after sometime")
            }
        }
    }

    func getUserProfileAndUpdateLocalStorage() {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.userProfile,
            expect: GetUserProfileResponseModel.self,
            requestType: APIConstants.GET
        ) { response, _, _ in
            if let apiResponse = response as? GetUserProfileResponseModel, let userData = apiResponse.data {

                let userName = "\(userData.firstName) \(userData.lastName ?? "")"
                FWUserDefaults.setStringForKey(key: .userNameKey, value: userName)
                FWUserDefaults.setStringForKey(key: .userEmailKey, value: userData.email)

                if let profileImage = userData.img {
                    FWUserDefaults.setStringForKey(key: .userImageKey, value: profileImage)
                }
            }
        }
    }

    func requestImageUpload(_ image: UIImage) {
        APIRequest().uploadImage(
            apiEndPoint: APIEndpoints.uploadImage,
            image: image,
            expect: UploadImageResponseModel.self
        ) { response, _, _ in
            if let response = response as? UploadImageResponseModel {
                if response.code.lowercased() == "success", let imageUrl = response.data?.url {
                    self.delegate?.profileImageUpdated(imageUrl[0])
                }else{
                    self.delegate?.error(message: response.message)
                }
            }
        }
    }

    func validate(_ model: UpdateProfileRequestModel) -> ValidationError {
        if model.firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            return .failure(message: "First name is required")
        }

        if model.lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            return .failure(message: "Last name is required")
        }

        if model.mobile.isEmpty {
            return .failure(message: "Phone number is required")
        }

        if model.mobile.count < 10 {
            return .failure(message: "Enter a valid phone number")
        }

        if model.title.isEmpty {
            return .failure(message: "Title is required")
        }

        return .success
    }
}
