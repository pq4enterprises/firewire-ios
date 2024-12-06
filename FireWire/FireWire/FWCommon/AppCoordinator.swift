//
//  AppCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import UIKit

class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        if isUserLoggedIn() {
            let homeCoordinator = HomeCoordinator(navigationController: navigationController)
            childCoordinators.append(homeCoordinator)
            homeCoordinator.parentCoordinator = self
            homeCoordinator.start()
        } else {
            let loginCoordinator = LoginCoordinator(navigationController: navigationController)
            childCoordinators.append(loginCoordinator)
            loginCoordinator.parentCoordinator = self
            loginCoordinator.start()
        }
    }

    func stop(){
        UserDefaults.standard.removeObject(forKey: "token")

        // Cleanup all child coordinators
        for coordinator in childCoordinators {
            coordinator.stop()
        }
        childCoordinators.removeAll()

        navigationController.popToRootViewController(animated: true)

        start() // reset
    }

    func isUserLoggedIn() -> Bool {
        UserDefaults.standard.object(forKey: "token") != nil
    }

    private func clearSessionData() {
        UserDefaults.standard.removeObject(forKey: "token")
        UserDefaults.standard.synchronize()
    }
}
