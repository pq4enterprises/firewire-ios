//
//  LoginCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import Foundation

class LoginCoordinator: BaseCoordinator {

    override func start() {
        let loginViewController = LoginViewController.instantiate()
        loginViewController.coordinator = self
        navigationController.pushViewController(loginViewController, animated: false)
    }

    func navigateToRegistration() {
        let registrationViewController = RegistrationViewController.instantiate()
        registrationViewController.coordinator = self
        navigationController.pushViewController(registrationViewController, animated: true)
    }

    func navigateToHome(){
        let homeCoordinator = HomeCoordinator(navigationController: self.navigationController)
        addChildCoordinator(homeCoordinator)
        homeCoordinator.start()
    }


}
