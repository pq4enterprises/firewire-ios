//
//  AppCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import GoogleSignIn
import UIKit
import FBSDKLoginKit
import OneSignalFramework

class AppCoordinator: BaseCoordinator {
    override func start() {
        isUserLoggedIn { isLoggedIn in
            if isLoggedIn {
                self.navigateToHome()
            } else {
                //self.navigateToLogin()
                self.navigateToSetDomain()
            }
        }
    }

    func navigateToSetDomain(){
        let loginCoordinator = LoginCoordinator(navigationController: navigationController)
        addChildCoordinator(loginCoordinator)
        loginCoordinator.parentCoordinator = self
        loginCoordinator.setDomainView()
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
        if UserDefaults.standard.object(forKey: "token") != nil {
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

        if AccessToken.current != nil {
            completion(true)
        }else{
            completion(false)
        }
    }

    private func clearSessionData() {
        if let _ = UserDefaults.standard.object(forKey: "token") {
            UserDefaults.standard.removeObject(forKey: "token")
        }
        UserDefaults.standard.synchronize()

        //Logout google sign in
        GIDSignIn.sharedInstance.signOut()

        //Facebook logout
        AccessToken.current = nil

        //Notification logout
        OneSignal.logout()
    }
}
