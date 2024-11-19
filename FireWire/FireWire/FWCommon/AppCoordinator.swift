//
//  AppCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import UIKit

class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var loginCoordinator: LoginCoordinator?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        if isUserLoggedIn() {
            // Navigate to main app flow (if user is logged in)
            // Example: show home screen, etc.
        } else {
            loginCoordinator = LoginCoordinator(navigationController: navigationController)
            loginCoordinator?.start()
        }
    }

    func isUserLoggedIn() -> Bool {
        // Check user authentication state (for demo purposes, we'll just return false)
        return false
    }
}
