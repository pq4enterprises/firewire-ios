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

    @discardableResult
    func navigateToLogin() -> LoginCoordinator {
        let loginCoordinator = LoginCoordinator(navigationController: navigationController)
        addChildCoordinator(loginCoordinator)
        loginCoordinator.parentCoordinator = self
        loginCoordinator.start()
        return loginCoordinator
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

    /// Tears down the dead session and recovers in two redundant layers: the full
    /// login screen is routed underneath, and a session-expired modal with its own
    /// email/password/Forgot Password is presented at window level on top. The modal
    /// survives any navigation-stack race (several screens fire API calls at once
    /// when a session dies, and a push mid-transition can be silently dropped), so
    /// the user is never stranded behind a dead-end "Ok" alert.
    func handleSessionExpired() {
        // Recovery already in progress — don't tear down the coordinator the
        // presented modal's callbacks are wired to.
        if sessionExpiredModalIsPresented() {
            FWSessionExpiry.reset()
            return
        }

        clearSessionData()

        for coordinator in childCoordinators {
            coordinator.backToParentCoordinator()
        }
        childCoordinators.removeAll()

        navigationController.popToRootViewController(animated: false)
        let loginCoordinator = navigateToLogin()
        presentSessionExpiredModal(loginCoordinator: loginCoordinator)

        FWSessionExpiry.reset()
    }

    private func sessionExpiredModalIsPresented() -> Bool {
        var top: UIViewController = navigationController
        while let presented = top.presentedViewController {
            if presented is SessionExpiredViewController { return true }
            top = presented
        }
        return false
    }

    private func presentSessionExpiredModal(loginCoordinator: LoginCoordinator) {
        var top: UIViewController = navigationController
        while let presented = top.presentedViewController {
            top = presented
        }

        // A stray error alert from an in-flight call would block the modal —
        // clear it and present from whatever was underneath.
        if let alert = top as? UIAlertController, let presenter = alert.presentingViewController {
            alert.dismiss(animated: false)
            top = presenter
        }

        guard !(top is SessionExpiredViewController) else { return }

        let modal = SessionExpiredViewController()
        modal.onSignedIn = { [weak loginCoordinator] in
            // Same routing the login screen itself uses after a successful sign-in
            loginCoordinator?.navigateToHome()
        }
        modal.onForgotPassword = { [weak loginCoordinator] in
            loginCoordinator?.navigateToForgotPassword()
        }
        modal.modalPresentationStyle = .overFullScreen
        modal.modalTransitionStyle = .crossDissolve
        top.present(modal, animated: true)
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
