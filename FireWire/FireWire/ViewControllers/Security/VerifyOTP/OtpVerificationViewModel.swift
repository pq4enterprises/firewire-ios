//
//  OtpVerificationViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/06/26.
//

import Foundation

public enum OTPVerificationType {
    case registration
    case forgotPassword
    case existingUser
}

final class OtpVerificationViewModel: OtpVerificationProtocol {
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
            apiEndPoint: APIEndpoints.verifyOtp,
            payload: APIPayload.verifyOtp(email: email, otp: otp).toDictionary(),
            expect: VerifyOtpResponseModel.self
        ) { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.otpVerificationFailure(errorMessage: errorMessage)
                return
            }

            guard let apiResponse = response as? VerifyOtpResponseModel else {
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

            self?.delegate?.otpVerificationSuccess(data: data)
        }
    }

    func resendOtp() {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.forgotPassword,
            payload: APIPayload.forgotPassword(email: email).toDictionary(),
            expect: ForgotPasswordResponseModel.self
        ) { [weak self] response, _, error in

            if let errorMessage = error {
                self?.delegate?.otpVerificationFailure(errorMessage: errorMessage)
                return
            }

            guard let apiResponse = response else {
                self?.delegate?.otpVerificationFailure(errorMessage: "Technical error, please try again!")
                return
            }

            if let response = apiResponse as? ForgotPasswordResponseModel {
                if response.code.lowercased() == "success" {
                    self?.delegate?.resendOtpSuccess(message: response.message)
                }
            }
        }
    }
}
