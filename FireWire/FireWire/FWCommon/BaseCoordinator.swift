//
//  BaseCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 19/11/24.
//

import UIKit

protocol Coordinator {
    var navigationController: UINavigationController { get }
    func start()
}

class BaseCoordinator: Coordinator {
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.navigationController.navigationBar.tintColor = .black
    }

    func start() {
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
}

