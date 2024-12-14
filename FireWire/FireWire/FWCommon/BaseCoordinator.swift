//
//  BaseCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get set }
    var childCoordinators: [Coordinator] { get set }
    func start()
    func backToParentCoordinator()
}

class BaseCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    var modalPresentationStyle: UIModalPresentationStyle = .none

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.navigationController.navigationBar.tintColor = .black
    }

    func start() {
        // This method should be overridden in subclasses
    }

    func backToParentCoordinator() {
        self.navigationController.viewControllers.removeAll()
    }

    func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if modalPresentationStyle != .none {
            presentView(viewController, animated: animated)
        }

        navigationController.pushViewController(viewController, animated: animated)
    }

    private func presentView(_ viewController: UIViewController, animated: Bool) {
        navigationController.present(viewController, animated: animated, completion: nil)
    }

    func popView() {
        if modalPresentationStyle != .none {
            navigationController.dismiss(animated: true)
        }
        navigationController.popViewController(animated: true)
    }

    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    func removeChildCoordinator(_ coordinator: Coordinator) {
        if let index = childCoordinators.firstIndex(where: { $0 === coordinator }) {
            childCoordinators.remove(at: index)
        }
    }

    func dismissView(animated: Bool){
        navigationController.dismiss(animated: true)
    }

    func openURL(_ urlString: String){
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

