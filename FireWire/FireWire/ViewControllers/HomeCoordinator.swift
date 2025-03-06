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
        homeViewController.appCoordinator = parentCoordinator
        homeViewController.coordinator = self
        pushViewController(homeViewController, animated: true)
    }

    func navigateToIncidentDetail(_ incidentID: String){
        let postDetailViewController = IncidentDetailViewController.instantiate()
        postDetailViewController.setSelectedIncidentID(incidentID)
        postDetailViewController.coordinator = self
        pushViewController(postDetailViewController, animated: true)
    }

    func navigateToMenu(){
        let menuViewController = MenuViewController.instantiate()
        menuViewController.appCoordinator = parentCoordinator
        menuViewController.coordinator = self
        navigationController.pushViewControllerFromLeft(controller: menuViewController, animated: false)
    }

    func navigateToFeeds(){
        let feedsViewController = FeedsListViewController.instantiate()
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

    func navigateToIncidentList(_ incidentListData: [IncidentDataModel]){
        let incidentsCoordinator = IncidentsCoordinator(navigationController: self.navigationController)
        addChildCoordinator(incidentsCoordinator)
        incidentsCoordinator.start(with: incidentListData, nil)
    }

    func navigateToMyAccount(){
        let myAccountViewController = MyAccountViewController.instantiate()
        myAccountViewController.appCoordinator = parentCoordinator
        myAccountViewController.coordinator = self
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

    func navigateToNotificationLocalityView(_ localityResponseData: LocalityResponseData){
        let notificationLocalityViewController = NotificationLocalityViewController.instantiate()
        notificationLocalityViewController.localityData = localityResponseData
        notificationLocalityViewController.coordinator = self
        pushViewController(notificationLocalityViewController, animated: true)
    }

    func navigateToUpdateProfile(){
        let updateProfileViewController = UpdateProfileViewController.instantiate()
        updateProfileViewController.coordinator = self
        pushViewController(updateProfileViewController, animated: true)
    }

    func navigateToChangePassword(){
        let changePasswordViewController = ChangePasswordViewController.instantiate()
        changePasswordViewController.coordinator = self
        pushViewController(changePasswordViewController, animated: true)
    }

    func navigateToSelectAreaListView(){
        let selectAreaListView = IncidentLocalityListViewController(viewModel: IncidentLocalityListViewModel())
        selectAreaListView.coordinator = self

        let bottomSheet = FWBottomSheetViewController.instantiate()
        bottomSheet.configure(with: selectAreaListView, isDraggableView: false, bottomSheetDetents: [.large])
        bottomSheet.showDimmedView = true
        bottomSheet.modalPresentationStyle = .pageSheet
        navigationController.present(bottomSheet, animated: true)
    }

    /// Copy of IncidentLocalityListViewController, just using different view controller for UI & navigation purpose
    func navigateToFeedAreaListView(){
        let feedAreaListView = FeedAreaListViewController.instantiate()
        feedAreaListView.viewModel = IncidentLocalityListViewModel()
        feedAreaListView.coordinator = self
        navigationController.pushViewController(feedAreaListView, animated: true)
    }

    func navigateToIncidentComments(_ incidentID: String, _ attachedImages: [UIImage] = []){
        let commentsList = CommentsViewController.instantiate()
        commentsList.setSelectedIncidentID(incidentID)
        commentsList.attachedImages = attachedImages
        commentsList.coordinator = self

        let navVC = UINavigationController(rootViewController: commentsList)
        navVC.modalPresentationStyle = .pageSheet

        if let sheet = navVC.sheetPresentationController {
            sheet.detents = [.medium(), .custom(resolver: {context in
                0.95 * context.maximumDetentValue
            })]
            sheet.prefersGrabberVisible = true
        }
        navigationController.present(navVC, animated: true)
    }

    func navigateToTakePicture(forIncident incidentID: String){
        let takePictureViewController = TakePictureViewController.instantiate()
        takePictureViewController.coordinator = self
        takePictureViewController.selectedIncidentID = incidentID
        takePictureViewController.isModalInPresentation = true  // Disable dismissing by tapping outside

        let navVC = UINavigationController(rootViewController: takePictureViewController)
        navVC.modalPresentationStyle = .pageSheet

        if let sheet = navVC.sheetPresentationController {
            sheet.detents = [.custom(resolver: {context in
                0.30 * context.maximumDetentValue
            })]
            sheet.prefersGrabberVisible = true
        }
        navigationController.present(navVC, animated: true)

    }

    func navigateToSubscriptionInfo(){
        let subscriptionView = SubscriptionInfoViewController.instantiate()
        subscriptionView.modalPresentationStyle = .overFullScreen
        subscriptionView.coordinator = self
        navigationController.present(subscriptionView, animated: true)
    }
}
