//
//  HomeCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import Foundation

class HomeCoordinator: BaseCoordinator {
    weak var parentCoordinator: AppCoordinator?

    override func start() {
        let homeViewController = HomeViewController.instantiate()
        homeViewController.coordinator = self
        navigationController.pushViewController(homeViewController, animated: true)
    }

    func navigateToMenu(){
        let menuViewController = MenuViewController.instantiate()
        menuViewController.coordinator = self
        navigationController.pushViewControllerFromLeft(controller: menuViewController, animated: false)
    }

    func navigateToFeeds(){
        let feedsViewController = FeedsViewController.instantiate()
        feedsViewController.coordinator = self
        navigationController.pushViewController(feedsViewController, animated: true)
    }

    func navigateBackToHome(popViewToLeft: Bool = false){
        if popViewToLeft {
            navigationController.popViewControllerToLeft(animated: false)
        } else {
            navigationController.popViewController(animated: true)
        }
    }

    func dismissView(){
        navigationController.dismiss(animated: true)
    }

    func popView(){
        navigationController.popViewController(animated: true)
    }

    func navigateToPostListView(){
        let postListView = PostListViewController()
        postListView.coordinator = self

        let bottomSheet = FWBottomSheetViewController.instantiate()
        bottomSheet.configure(with: postListView, bottomSheetDetents: [.medium, .large])
        bottomSheet.modalPresentationStyle = .overCurrentContext
        navigationController.present(bottomSheet, animated: true)
    }

    func navigateToSelectAreaListView(){
        let selectAreaListView = SelectAreaListViewController()
        selectAreaListView.coordinator = self

        let bottomSheet = FWBottomSheetViewController.instantiate()
        bottomSheet.configure(with: selectAreaListView, isDraggableView: false, bottomSheetDetents: [.large])
        bottomSheet.modalPresentationStyle = .overCurrentContext
        navigationController.present(bottomSheet, animated: true)
    }

    func navigateToPostDetail(){
        let postDetailViewController = PostDetailViewController.instantiate()
        postDetailViewController.coordinator = self
        navigationController.pushViewController(postDetailViewController, animated: true)
    }

    func navigateToNewsDetail(){
        let newsDetailViewController = NewsDetailViewController.instantiate()
        newsDetailViewController.coordinator = self
        navigationController.pushViewController(newsDetailViewController, animated: true)
    }

    func navigateToMyAccount(){
        let myAccountViewController = MyAccountViewController.instantiate()
        myAccountViewController.coordinator = self
        navigationController.pushViewController(myAccountViewController, animated: true)
    }

    override func stop(){
        parentCoordinator?.stop()
    }
}
