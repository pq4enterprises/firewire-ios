//
//  OtpVerificationProtocol.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/06/26.
//

import Foundation

protocol OtpVerificationViewModelDelegate: AnyObject {
    func otpVerificationSuccess(data: VerifyOtpResponseData?)
    func otpVerificationFailure(errorMessage: String)
    func resendOtpSuccess(message: String)
}

protocol OtpVerificationProtocol: AnyObject {
    var email: String { get }
    var delegate: OtpVerificationViewModelDelegate? { get set }
    
    func updateOtp(_ otp: String)
    func submitOtp()
    func resendOtp()
}
