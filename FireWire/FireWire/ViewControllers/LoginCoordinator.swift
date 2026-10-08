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

    func navigateToOtpVerification(email: String){
        let otpVerificationViewController = OtpVerificationViewController.instantiate()
        otpVerificationViewController.email = email
        otpVerificationViewController.coordinator = self
        pushViewController(otpVerificationViewController, animated: true)
    }

    func navigateToResetPassword(token: String){
        let resetPasswordViewController = ResetPasswordViewController.instantiate()
        resetPasswordViewController.coordinator = self
        resetPasswordViewController.resetToken = token
        pushViewController(resetPasswordViewController, animated: true)
    }

    /// Email verification (the server has already emailed the code).
    func navigateToVerifyEmail(email: String, origin: VerifyEmailOrigin) {
        let verifyEmailViewController = VerifyEmailViewController()
        verifyEmailViewController.email = email
        verifyEmailViewController.origin = origin
        verifyEmailViewController.coordinator = self
        pushViewController(verifyEmailViewController, animated: true)
    }

    /// After verifying an unverified email mid-reset, drop back to the forgot
    /// password screen (still on the stack) so the user can request the reset code.
    func returnToForgotPasswordAfterVerification() {
        if let forgot = navigationController.viewControllers.last(where: { $0 is ForgotPasswordViewController }) as? ForgotPasswordViewController {
            forgot.pendingVerifiedNotice = true
            navigationController.popToViewController(forgot, animated: true)
        } else {
            navigateToForgotPassword()
        }
    }

    func navigateToSelectArea(){
        let selectAreaViewController = SelectAreaViewController.instantiate()
        selectAreaViewController.parentCoordinator = parentCoordinator
        pushViewController(selectAreaViewController, animated: true)
    }

}
