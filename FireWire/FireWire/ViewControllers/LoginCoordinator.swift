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
        pushViewController(registrationViewController, animated: true)
    }

    func navigateToHome(){
        let homeCoordinator = HomeCoordinator(navigationController: self.navigationController)
        addChildCoordinator(homeCoordinator)
        homeCoordinator.start()
    }

    func navigateToForgotPassword(){
        let forgotPasswordViewController = ForgotPasswordViewController.instantiate()
        forgotPasswordViewController.coordinator = self
        pushViewController(forgotPasswordViewController, animated: true)
    }

    func navigateToOtpVerification(){
        let otpVerificationViewController = OtpVerificationViewController.instantiate()
        otpVerificationViewController.coordinator = self
        pushViewController(otpVerificationViewController, animated: true)
    }

    func navigateToResetPassword(){
        let resetPasswordViewController = ResetPasswordViewController.instantiate()
        resetPasswordViewController.coordinator = self
        pushViewController(resetPasswordViewController, animated: true)
    }

}
