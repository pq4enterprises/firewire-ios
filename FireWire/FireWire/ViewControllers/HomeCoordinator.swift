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

    func navigateToIncidentDetail(_ incidentID: String, openComments: Bool = false){
        let postDetailViewController = IncidentDetailViewController.instantiate()
        postDetailViewController.setSelectedIncidentID(incidentID, openComments)
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

    func navigateToNotificationSounds(){
        let notificationSoundsViewController = NotificationSoundsViewController.instantiate()
        notificationSoundsViewController.coordinator = self
        pushViewController(notificationSoundsViewController, animated: true)
    }

    func navigateToNotificationLocalityView(_ allLocalities: [LocalityResponseData], _ localityResponseData: LocalityResponseData){
        let notificationLocalityViewController = NotificationLocalityViewController.instantiate()
        notificationLocalityViewController.localityData = localityResponseData
        notificationLocalityViewController.allLocalities = allLocalities
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

    func navigateToSelectAreaListView(_ delegate: FilterAreaDelegate?){
        let viewModel = IncidentLocalityListViewModel()
        viewModel.filterAreaDelegate = delegate
        let selectAreaListView = IncidentLocalityListViewController(viewModel: viewModel)
        selectAreaListView.coordinator = self

        if let sheet = selectAreaListView.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        selectAreaListView.modalPresentationStyle = .pageSheet
        navigationController.present(selectAreaListView, animated: true)
    }

    /// Copy of IncidentLocalityListViewController, just using different view controller for UI & navigation purpose
    func navigateToFeedAreaListView(){
        let feedAreaListView = FeedAreaListViewController.instantiate()
        feedAreaListView.viewModel = IncidentLocalityListViewModel()
        feedAreaListView.coordinator = self
        navigationController.pushViewController(feedAreaListView, animated: true)
    }

    func navigateToIncidentComments(_ incidentComments: SelectedIncidentCommentsModel, _ attachedImages: [UIImage] = []){
        let commentsList = CommentsViewController.instantiate()
        commentsList.setSelectedIncidentID(incidentComments)
        commentsList.attachedImages = attachedImages
        commentsList.coordinator = self

        let navVC = UINavigationController(rootViewController: commentsList)
        navVC.modalPresentationStyle = .pageSheet

        if let sheet = navVC.sheetPresentationController {
            sheet.detents = [
                .medium(),
                .custom(identifier: .init("custom"), resolver: { context in
                    0.95 * context.maximumDetentValue
                })
            ]
            sheet.selectedDetentIdentifier = .init("custom")
            sheet.prefersGrabberVisible = true
        }
        navigationController.present(navVC, animated: true)
    }

    func navigateToTakePicture(forIncidentComments incidentComments: SelectedIncidentCommentsModel){
        let takePictureViewController = TakePictureViewController.instantiate()
        takePictureViewController.coordinator = self
        //takePictureViewController.selectedIncidentID = incidentID
        takePictureViewController.selectedIncidentComments = incidentComments
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

    func navigateToPostWebView(){
        let postWebViewController = PostWebViewController.instantiate()
        postWebViewController.coordinator = self
        pushViewController(postWebViewController, animated: true)
    }

    func navigateToSelectArea(){
        let selectAreaViewController = SelectAreaViewController.instantiate()
        selectAreaViewController.parentCoordinator = parentCoordinator
        pushViewController(selectAreaViewController, animated: false)
    }

    func navigateToGettinSaltyMenu(){
        let saltyMenuView = GettinSaltyMenuViewController.instantiate()
        saltyMenuView.coordinator = self
        pushViewController(saltyMenuView, animated: true)
    }

    func navigateToOTPVerification(email: String, verificationType: OTPVerificationType) {
        let viewModel: OtpVerificationProtocol = EmailOtpVerificationViewModel(email: email, otp: "")
        let otpViewController = OtpVerificationViewController.instantiate(viewModel: viewModel, verificationType: verificationType)
        otpViewController.homeCoordinator = self
        pushViewController(otpViewController, animated: true)
    }
}
