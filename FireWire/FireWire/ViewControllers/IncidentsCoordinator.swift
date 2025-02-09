//
//  IncidentsCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 13/12/24.
//

import Foundation
import UIKit

class IncidentsCoordinator: BaseCoordinator {
    func start(with incidentListData: [IncidentDataModel], _ selectedLocalities: SelectedLocalities?) {
        let viewModel = IncidentListViewModel(incidentListData,selectedLocalities)
        let postListView = IncidentListViewController(viewModel: viewModel)
        postListView.coordinator = self

        let bottomSheet = FWBottomSheetViewController.instantiate()
        bottomSheet.configure(with: postListView, bottomSheetDetents: [.medium, .large])
        bottomSheet.modalPresentationStyle = .overCurrentContext

        modalPresentationStyle = .formSheet
        pushViewController(bottomSheet, animated: true)
    }

    func navigateToIncidentDetail(_ incidentID: String){
        let postDetailViewController = IncidentDetailViewController.instantiate()
        postDetailViewController.setSelectedIncidentID(incidentID)
        //postDetailViewController.coordinator = self

        modalPresentationStyle = .none
        pushViewController(postDetailViewController, animated: true)
    }

    func navigateToSelectAreaListView(){
        let selectAreaListView = IncidentLocalityListViewController(viewModel: IncidentLocalityListViewModel())
        selectAreaListView.coordinator = self

        let bottomSheet = FWBottomSheetViewController.instantiate()
        bottomSheet.configure(with: selectAreaListView, isDraggableView: false, bottomSheetDetents: [.large])
        bottomSheet.modalPresentationStyle = .overCurrentContext
        navigationController.present(bottomSheet, animated: true)
    }

    func navigateToIncidentComments(_ incidentID: String, _ attachedImages: [String] = []){
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

    func navigateToShareView(shareMessage: String){
        let shareViewController = IncidentShareViewController.instantiate()
        shareViewController.shareMessage = shareMessage
        
        let navVC = UINavigationController(rootViewController: shareViewController)
        navVC.modalPresentationStyle = .pageSheet

        if let sheet = navVC.sheetPresentationController {
            sheet.detents = [.custom(resolver: {context in
                0.30 * context.maximumDetentValue
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
}
