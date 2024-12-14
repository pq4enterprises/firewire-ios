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
        let postListView = PostListViewController(viewModel: PostListViewModel())
        postListView.coordinator = self

        let bottomSheet = FWBottomSheetViewController.instantiate()
        bottomSheet.configure(with: postListView, bottomSheetDetents: [.medium, .large])
        bottomSheet.modalPresentationStyle = .overCurrentContext

        modalPresentationStyle = .formSheet
        pushViewController(bottomSheet, animated: true)
    }

    func navigateToPostDetail(_ incidentID: String){
        let postDetailViewController = PostDetailViewController.instantiate()
        postDetailViewController.setViewModel(viewModel: PostDetailViewModel(incidentID: incidentID))
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
