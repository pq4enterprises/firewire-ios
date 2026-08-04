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
        if VersionChecker.isBuildUpdateRequired() {
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

    /// Notification tap: land on the incident the push was about, not just the feed.
    /// Falls back to the normal start flow when there's no incident id, no session,
    /// or a forced update in the way.
    func handleNotificationTap(incidentId: String?) {
        guard let incidentId, !incidentId.isEmpty else {
            start()
            return
        }

        if VersionChecker.isBuildUpdateRequired() {
            navigateToForceUpdate()
            return
        }

        isUserLoggedIn { isLoggedIn in
            guard isLoggedIn else {
                self.navigateToLogin()
                return
            }

            let home = self.childCoordinators.compactMap { $0 as? HomeCoordinator }.last
                ?? {
                    let coordinator = HomeCoordinator(navigationController: self.navigationController)
                    self.addChildCoordinator(coordinator)
                    coordinator.parentCoordinator = self
                    coordinator.start()
                    return coordinator
                }()
            home.navigateToIncidentDetail(incidentId)
        }
    }

    /// Tears down the current session and drops the user on the login screen, which
    /// already carries email + password fields, Forgot Password, and social sign-in —
    /// so they can recover in place rather than being stranded behind an "Ok" button.
    func handleSessionExpired() {
        clearSessionData()

        for coordinator in childCoordinators {
            coordinator.backToParentCoordinator()
        }
        childCoordinators.removeAll()

        navigationController.popToRootViewController(animated: false)
        LoginViewController.pendingSessionExpiryNotice = true
        navigateToLogin()

        FWSessionExpiry.reset()
    }

    private func clearSessionData() {
        if let _ = FWUserDefaults().userToken {
            FWUserDefaults.removeObjectForKey(key: .userTokenKey)
        }

        // The refresh token was never cleared here, nor on sign-out. A dead — or worse,
        // still-live — refresh token surviving a sign-out on a shared device is both a
        // correctness and a privacy problem.
        FWUserDefaults.removeObjectForKey(key: .refreshTokenKey)

        //Logout google sign in
        GIDSignIn.sharedInstance.signOut()

        //Notification logout
        OneSignal.logout()
    }
}
