//
//  IncidentsCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 13/12/24.
//

import Foundation
import UIKit

class IncidentsCoordinator: BaseCoordinator {
    override func start() {
        let postListView = IncidentListViewController(viewModel: IncidentListViewModel())
        postListView.coordinator = self

        let bottomSheet = FWBottomSheetViewController.instantiate()
        bottomSheet.configure(with: postListView, bottomSheetDetents: [.medium, .large])
        bottomSheet.modalPresentationStyle = .overCurrentContext

        modalPresentationStyle = .formSheet
        pushViewController(bottomSheet, animated: true)
    }

    func navigateToPostDetail(_ incidentID: String){
        let postDetailViewController = IncidentDetailViewController.instantiate()
        postDetailViewController.setViewModel(viewModel: IncidentDetailViewModel(incidentID: incidentID))
        postDetailViewController.coordinator = self

        modalPresentationStyle = .none
        pushViewController(postDetailViewController, animated: true)
    }

    func navigateToSelectAreaListView(){
        let selectAreaListView = SelectAreaListViewController()
        selectAreaListView.coordinator = self

        let bottomSheet = FWBottomSheetViewController.instantiate()
        bottomSheet.configure(with: selectAreaListView, isDraggableView: false, bottomSheetDetents: [.large])
        bottomSheet.modalPresentationStyle = .overCurrentContext
        navigationController.present(bottomSheet, animated: true)
    }
}
