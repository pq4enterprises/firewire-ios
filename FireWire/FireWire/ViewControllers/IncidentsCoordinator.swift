//
//  IncidentsCoordinator.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 13/12/24.
//

import Foundation
import UIKit

class IncidentsCoordinator: BaseCoordinator {
     func start(with incidentListData: [IncidentDataModel]) {
         let viewModel = IncidentListViewModel(incidentListData)
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
        postDetailViewController.coordinator = self

        modalPresentationStyle = .none
        pushViewController(postDetailViewController, animated: true)
    }

    func navigateToSelectAreaListView(){
        let selectAreaListView = SelectAreaListViewController(viewModel: SelectAreaViewModel())
        selectAreaListView.coordinator = self

        let bottomSheet = FWBottomSheetViewController.instantiate()
        bottomSheet.configure(with: selectAreaListView, isDraggableView: false, bottomSheetDetents: [.large])
        bottomSheet.modalPresentationStyle = .overCurrentContext
        navigationController.present(bottomSheet, animated: true)
    }
}
