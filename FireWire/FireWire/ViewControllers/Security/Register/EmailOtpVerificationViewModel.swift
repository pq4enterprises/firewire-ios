//
//  RegistrationOtpVerificationViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/06/26.
//

import Foundation
import OneSignalFramework

final class EmailOtpVerificationViewModel: OtpVerificationProtocol {
    weak var delegate: OtpVerificationViewModelDelegate?
    let email: String
    private(set) var otp: String

    init(email: String, otp: String = "") {
        self.email = email
        self.otp = otp
    }

    func updateOtp(_ otp: String) {
        self.otp = otp
    }

    func submitOtp() {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.verifyEmailOtp,
            payload: APIPayload.verifyEmailOtp(email: email, otp: otp).toDictionary(),
            expect: VerifyEmailResponseModel.self
        ) { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.otpVerificationFailure(errorMessage: errorMessage)
                return
            }

            guard let apiResponse = response as? VerifyEmailResponseModel else {
                let errorMessage = (response == nil) ? "Invalid request" : "Unexpected response format"
                self?.delegate?.otpVerificationFailure(errorMessage: errorMessage)
                return
            }

            if apiResponse.code.lowercased() != "success" {
                self?.delegate?.otpVerificationFailure(errorMessage: apiResponse.message)
                return
            }

            guard let data = apiResponse.data else {
                self?.delegate?.otpVerificationFailure(errorMessage: "Technical error, please try again!")
                return
            }

            if let userId = data.id {
                OneSignal.login(userId)
            }

            FWUserDefaults.setStringForKey(key: .userIDKey, value: data.id)
            let userName = "\(data.firstName ?? "") \(data.lastName ?? "")"
            FWUserDefaults.setStringForKey(key: .userNameKey, value: userName)
            FWUserDefaults.setStringForKey(key: .userEmailKey, value: data.email)
            FWUserDefaults.setStringForKey(key: .userTokenKey, value: data.token)
            FWUserDefaults.setStringForKey(key: .refreshTokenKey, value: data.refreshToken)
            FWUserDefaults.setStringForKey(key: .userRoleKey, value: data.role)

            self?.delegate?.otpVerificationSuccess(data: nil)
        }
    }

    func resendOtp(){
        let emailModel = APIPayload.resendEmailOtp(email: email).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.resendEmailOtp,
            payload: emailModel as JSON,
            expect: ResendOTPForEmailResponseModel.self,
        ) { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.otpVerificationFailure(errorMessage: errorMessage)
                return
            }

            guard let apiResponse = response as? ResendOTPForEmailResponseModel else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self?.delegate?.otpVerificationFailure(errorMessage: errorMessage)
                return
            }

            if apiResponse.code == "success"{
                self?.delegate?.resendOtpSuccess(message: apiResponse.message)
            }else{
                self?.delegate?.otpVerificationFailure(errorMessage: apiResponse.message)
            }
        }
    }
}
