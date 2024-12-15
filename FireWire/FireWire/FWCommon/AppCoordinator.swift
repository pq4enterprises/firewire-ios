//
//  AppCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import UIKit

class AppCoordinator: BaseCoordinator {
    override func start() {
        if isUserLoggedIn() {
            navigateToHome()
        } else {
            navigateToLogin()
        }
    }

    func navigateToLogin(){
        let loginCoordinator = LoginCoordinator(navigationController: navigationController)
        addChildCoordinator(loginCoordinator)
        loginCoordinator.parentCoordinator = self
        loginCoordinator.start()
    }

    func navigateToHome(){
        let homeCoordinator = HomeCoordinator(navigationController: navigationController)
        addChildCoordinator(homeCoordinator)
        homeCoordinator.parentCoordinator = self
        homeCoordinator.start()
    }

    override func backToParentCoordinator(){
        clearSessionData()

        // Cleanup all child coordinators
        for coordinator in childCoordinators {
            coordinator.backToParentCoordinator()
        }
        childCoordinators.removeAll()

        navigationController.popToRootViewController(animated: true)

        start() // reset
    }

    func isUserLoggedIn() -> Bool {
        UserDefaults.standard.object(forKey: "token") != nil
    }

    private func clearSessionData() {
        if let _ = UserDefaults.standard.object(forKey: "token"){
            UserDefaults.standard.removeObject(forKey: "token")
        }
        UserDefaults.standard.synchronize()
    }
}
