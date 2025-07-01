//
//  AppCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import GoogleSignIn
import UIKit
import OneSignalFramework

class AppCoordinator: BaseCoordinator {
    override func start() {
        if VersionChecker.isUpdateRequired() {
            self.navigateToForceUpdate()
        }else{
            isUserLoggedIn { isLoggedIn in
                if isLoggedIn {
                    self.navigateToHome()
                } else {
                    self.navigateToLogin()
                }
            }
        }
    }

    func navigateToForceUpdate() {
        let vc = ForceUpdateViewController.instantiate()
        navigationController.setViewControllers([vc], animated: false)
    }

    func navigateToLogin() {
        let loginCoordinator = LoginCoordinator(navigationController: navigationController)
        addChildCoordinator(loginCoordinator)
        loginCoordinator.parentCoordinator = self
        loginCoordinator.start()
    }

    func navigateToHome() {
        let homeCoordinator = HomeCoordinator(navigationController: navigationController)
        addChildCoordinator(homeCoordinator)
        homeCoordinator.parentCoordinator = self
        homeCoordinator.start()
    }

    override func backToParentCoordinator() {
        clearSessionData()

        // Cleanup all child coordinators
        for coordinator in childCoordinators {
            coordinator.backToParentCoordinator()
        }
        childCoordinators.removeAll()

        navigationController.popToRootViewController(animated: true)

        start() // reset
    }

    func isUserLoggedIn(completion: @escaping (Bool) -> Void) {
        if FWUserDefaults().userToken != nil {
            completion(true)
            return
        }

        /// Google sign-in
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    private func clearSessionData() {
        if let _ = FWUserDefaults().userToken {
            FWUserDefaults.removeObjectForKey(key: .userTokenKey)
        }

        //Logout google sign in
        GIDSignIn.sharedInstance.signOut()

        //Notification logout
        OneSignal.logout()
    }
}
