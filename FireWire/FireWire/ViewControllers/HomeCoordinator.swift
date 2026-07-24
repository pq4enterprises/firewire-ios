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

    func navigateToIncidentDetail(_ incidentID: String, openComments: Bool = false, subLocalityName: String? = nil){
        let postDetailViewController = IncidentDetailViewController.instantiate()
        postDetailViewController.setSelectedIncidentID(incidentID, openComments, subLocalityName: subLocalityName)
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
        let scannerViewController = ScannerViewController.instantiate()
        scannerViewController.coordinator = self
        pushViewController(scannerViewController, animated: true)
    }

    func navigateBackToHome(popViewToLeft: Bool = false){
        if popViewToLeft {
            navigationController.popViewControllerToLeft(animated: false)
        } else {
            navigationController.popViewController(animated: true)
        }
    }

    func navigateToMyAccount(){
        let profileViewController = ProfileViewController.instantiate()
        profileViewController.appCoordinator = parentCoordinator
        profileViewController.coordinator = self
        pushViewController(profileViewController, animated: true)
    }

    func navigateToAreasAlerts(){
        let areasAlertsViewController = AreasAlertsViewController.instantiate()
        areasAlertsViewController.coordinator = self
        pushViewController(areasAlertsViewController, animated: true)
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
        let editProfileViewController = EditProfileViewController.instantiate()
        editProfileViewController.coordinator = self
        pushViewController(editProfileViewController, animated: true)
    }

    func navigateToChangePassword(){
        let changePasswordViewController = ChangePasswordViewController.instantiate()
        changePasswordViewController.coordinator = self
        pushViewController(changePasswordViewController, animated: true)
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
        // The subscription paywall now lives inside the redesigned Profile
        // screen — present it modally wherever the old paywall was triggered.
        let profileViewController = ProfileViewController.instantiate()
        profileViewController.appCoordinator = parentCoordinator
        profileViewController.coordinator = self
        profileViewController.isModalPaywall = true
        profileViewController.modalPresentationStyle = .fullScreen
        navigationController.present(profileViewController, animated: true)
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

}
