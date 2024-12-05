//
//  AppCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import UIKit

class AppCoordinator: Coordinator {
    var childCoordinators: [any Coordinator]?
    var navigationController: UINavigationController
    var loginCoordinator: LoginCoordinator?
    var homeCoordinator: HomeCoordinator?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        if isUserLoggedIn() {
            // Change to home screen
            loginCoordinator = LoginCoordinator(navigationController: navigationController)
            loginCoordinator?.start()
        } else {
            loginCoordinator = LoginCoordinator(navigationController: navigationController)
            loginCoordinator?.start()
        }
    }

    func isUserLoggedIn() -> Bool {
        UserDefaults.standard.object(forKey: "token") != nil
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: "token")

        let loginCoordinator = LoginCoordinator(navigationController: navigationController)
        loginCoordinator.start()
    }

    private func clearSessionData() {
        UserDefaults.standard.removeObject(forKey: "token")
        UserDefaults.standard.synchronize()
    }
}
