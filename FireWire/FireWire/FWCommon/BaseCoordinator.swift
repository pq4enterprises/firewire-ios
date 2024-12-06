//
//  BaseCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var childCoordinators: [Coordinator] { get set }
    func start()
    func stop()
}

class BaseCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.navigationController.navigationBar.tintColor = .black
    }

    func start() {
        // This method should be overridden in subclasses
    }

    func stop() {
        // This method should be overridden in subclasses
    }

    func push(_ viewController: UIViewController) {
        navigationController.pushViewController(viewController, animated: true)
    }

    func pop() {
        navigationController.popViewController(animated: true)
    }

    func present(_ viewController: UIViewController, animated: Bool) {
        navigationController.present(viewController, animated: animated, completion: nil)
    }

    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    func removeChildCoordinator(_ coordinator: Coordinator) {
        if let index = childCoordinators.firstIndex(where: { $0 === coordinator }) {
            childCoordinators.remove(at: index)
        }
    }
}

