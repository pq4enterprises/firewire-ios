//
//  PremiumAlertsPrompt.swift
//  FireWire
//
//  Iteration 1 — right after a user becomes premium, offer to set up alerts
//  ("You're Premium" → Choose alerts / Later). Fired from two places:
//
//    1. The in-app purchase success path (ProfileViewController, after
//       api/app/payment + the profile role refresh) via `presentAfterPurchase`.
//    2. `PremiumStatusChanged`, posted by SubscriptionManager after an
//       offer-code / external transaction has been reported — handled here by
//       watching for the basic_user → premium role transition.
//
//  Shown once per purchase event: the role snapshot flips to premium as soon
//  as the prompt is shown, so later notifications (or launches) stay quiet.
//

import UIKit

final class PremiumAlertsPrompt {
    static let shared = PremiumAlertsPrompt()

    static let title = "You're Premium"
    static let message = "Choose which areas, incident types and units alert you."

    private weak var coordinator: HomeCoordinator?
    private var observer: NSObjectProtocol?
    /// Role snapshot used to detect the basic → premium transition.
    private var lastKnownRole: String?

    private init() {}

    // MARK: Observing

    /// Called when the Home coordinator starts (after sign-in). Re-arms the
    /// role snapshot for the signed-in account.
    func startObserving(coordinator: HomeCoordinator) {
        self.coordinator = coordinator
        lastKnownRole = FWUserDefaults().userRole
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("PremiumStatusChanged"), object: nil, queue: .main
        ) { [weak self] _ in
            self?.handlePremiumStatusChanged()
        }
    }

    private func handlePremiumStatusChanged() {
        let role = FWUserDefaults().userRole
        defer { lastKnownRole = role }
        guard let coordinator,
              Self.isBasic(lastKnownRole), !Self.isBasic(role), role != nil
        else { return }
        guard let presenter = topViewController(from: coordinator.navigationController) else { return }
        present(from: presenter, coordinator: coordinator)
    }

    // MARK: Presenting

    /// In-app purchase path. `roleBeforePurchase` lets a restore by an
    /// already-premium account skip the prompt.
    func presentAfterPurchase(from presenter: UIViewController, coordinator: HomeCoordinator?, roleBeforePurchase: String?) {
        let role = FWUserDefaults().userRole
        lastKnownRole = role   // this purchase is handled; a trailing notification must not re-prompt
        guard Self.isBasic(roleBeforePurchase), !Self.isBasic(role), let coordinator else {
            presenter.showAlert(
                title: "",
                message: MyAccountViewModel.subscriptionSuccessMessage,
                actions: [UIAlertAction(title: "Ok", style: .cancel)])
            return
        }
        present(from: presenter, coordinator: coordinator)
    }

    private func present(from presenter: UIViewController, coordinator: HomeCoordinator) {
        // Never stack on top of an alert already showing.
        if presenter is UIAlertController { return }

        let alert = UIAlertController(title: Self.title, message: Self.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Choose alerts", style: .default) { [weak coordinator] _ in
            guard let coordinator else { return }
            Self.navigateToAreasAlerts(coordinator: coordinator)
        })
        alert.addAction(UIAlertAction(title: "Later", style: .cancel))
        presenter.present(alert, animated: true)
    }

    /// Dismisses any modal (e.g. the paywall) first, then pushes Areas & Alerts
    /// unless it is already on top.
    private static func navigateToAreasAlerts(coordinator: HomeCoordinator) {
        let navigation = coordinator.navigationController
        let push = {
            if navigation.topViewController is AreasAlertsViewController { return }
            coordinator.navigateToAreasAlerts()
        }
        if navigation.presentedViewController != nil {
            navigation.dismiss(animated: true, completion: push)
        } else {
            push()
        }
    }

    // MARK: Helpers

    private static func isBasic(_ role: String?) -> Bool {
        role == "basic_user"
    }

    private func topViewController(from root: UIViewController) -> UIViewController? {
        var top: UIViewController = root
        while let presented = top.presentedViewController {
            top = presented
        }
        if let navigation = top as? UINavigationController {
            return navigation.visibleViewController ?? navigation
        }
        return top
    }
}
