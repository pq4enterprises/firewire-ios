//
//  LoginCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import Foundation

class LoginCoordinator: BaseCoordinator {
    weak var parentCoordinator: AppCoordinator?

    override func start() {
        let loginViewController = LoginViewController.instantiate()
        loginViewController.coordinator = self
        loginViewController.parentCoordinator = parentCoordinator
        pushViewController(loginViewController, animated: false)
    }

    func navigateToRegistration() {
        let registrationViewController = RegistrationViewController.instantiate()
        registrationViewController.coordinator = self
        registrationViewController.parentCoordinator = parentCoordinator
        pushViewController(registrationViewController, animated: true)
    }

    func navigateToHome() {
        let homeCoordinator = HomeCoordinator(navigationController: navigationController)
        addChildCoordinator(homeCoordinator)
        homeCoordinator.start()
    }

    func navigateToForgotPassword() {
        let forgotPasswordViewController = ForgotPasswordViewController.instantiate()
        forgotPasswordViewController.coordinator = self
        pushViewController(forgotPasswordViewController, animated: true)
    }

    func navigateToOTPVerification(email: String, verificationType: OTPVerificationType) {
        let viewModel: OtpVerificationProtocol = verificationType == .forgotPassword
            ? OtpVerificationViewModel(email: email, otp: "")
            : RegistrationOtpVerificationViewModel(email: email, otp: "")

        let otpViewController = OtpVerificationViewController.instantiate(viewModel: viewModel, verificationType: verificationType)
        otpViewController.coordinator = self
        pushViewController(otpViewController, animated: true)
    }

    func navigateToResetPassword(token: String) {
        let resetPasswordViewController = ResetPasswordViewController.instantiate()
        resetPasswordViewController.coordinator = self
        resetPasswordViewController.resetToken = token
        pushViewController(resetPasswordViewController, animated: true)
    }

    func navigateToSelectArea() {
        let selectAreaViewController = SelectAreaViewController.instantiate()
        selectAreaViewController.parentCoordinator = parentCoordinator
        pushViewController(selectAreaViewController, animated: true)
    }
}
