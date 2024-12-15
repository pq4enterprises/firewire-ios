//
//  HomeCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import Foundation
import UIKit

class HomeCoordinator: BaseCoordinator {
    weak var parentCoordinator: AppCoordinator?

    override func start() {
        let homeViewController = HomeViewController.instantiate()
        homeViewController.coordinator = self
        pushViewController(homeViewController, animated: true)
    }

    func navigateToMenu(){
        let menuViewController = MenuViewController.instantiate()
        menuViewController.coordinator = self
        navigationController.pushViewControllerFromLeft(controller: menuViewController, animated: false)
    }

    func navigateToFeeds(){
        let feedsViewController = FeedsViewController.instantiate()
        feedsViewController.coordinator = self
        pushViewController(feedsViewController, animated: true)
    }

    func navigateBackToHome(popViewToLeft: Bool = false){
        if popViewToLeft {
            navigationController.popViewControllerToLeft(animated: false)
        } else {
            navigationController.popViewController(animated: true)
        }
    }

    func navigateToIncidentList(){
        let homeCoordinator = IncidentsCoordinator(navigationController: self.navigationController)
        addChildCoordinator(homeCoordinator)
        homeCoordinator.start()
    }

    func navigateToNewsDetail(_ newsID: String){
        let newsDetailViewController = NewsDetailViewController.instantiate()
        newsDetailViewController.setViewModel(viewModel: NewsDetailViewModel(newsID: newsID))
        newsDetailViewController.coordinator = self
        pushViewController(newsDetailViewController, animated: true)
    }

    func navigateToMyAccount(){
        let myAccountViewController = MyAccountViewController.instantiate()
        myAccountViewController.coordinator = parentCoordinator
        pushViewController(myAccountViewController, animated: true)
    }

    func navigateToPersonalisation(){
        let personalisationViewController = PersonalisationViewController.instantiate()
        personalisationViewController.coordinator = self
        pushViewController(personalisationViewController, animated: true)
    }

    func navigateToNotificationSettings(){
        let notificationSettingsViewController = NotificationSettingsViewController.instantiate()
        notificationSettingsViewController.coordinator = self
        pushViewController(notificationSettingsViewController, animated: true)
    }

    func navigateToNotificationLocalityView(){
        let notificationLocalityViewController = NotificationLocalityViewController.instantiate()
        notificationLocalityViewController.coordinator = self
        pushViewController(notificationLocalityViewController, animated: true)
    }
}
