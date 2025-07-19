//
//  IncidentHomeViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 17/07/25.
//

import Pulley
import UIKit

protocol IncidentDrawerDelegate {
    func incidentListExpanded(_ value: Bool)
}

class IncidentHomeViewController: PulleyViewController {
    var appCoordinator: AppCoordinator?
    var coordinator: HomeCoordinator?
    var incidentsViewModel: IncidentsViewModel?
    var paginationHandler: PaginationHandler<IncidentsViewModel>!
    var incidentDrawerDelegate: IncidentDrawerDelegate?
    var forceRefresh: Bool = false

    var drawerVC: IncidentListViewController? {
        return drawerContentViewController as? IncidentListViewController
    }

    var contentVC: IncidentMapViewController? {
        return primaryContentViewController as? IncidentMapViewController
    }

    @IBOutlet weak var changeViewButton: FWRoundedButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        drawerVC?.delegate = self
        drawerVC?.coordinator = coordinator

        incidentsViewModel = IncidentsViewModel()
        incidentsViewModel?.delegate = self

        paginationHandler = PaginationHandler(viewModel: incidentsViewModel!)

        changeViewButton.isHidden = true
        changeViewButton.setupShadow()
        self.view.bringSubviewToFront(changeViewButton)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchIncidents()
    }

    func fetchIncidents(forceRefresh: Bool = false) {
        showLoader()
        incidentsViewModel?.currentPage = 1
        incidentsViewModel?.items.removeAll()
        incidentsViewModel?.markersList.removeAll()
        incidentsViewModel?.getIncidentList()
        self.forceRefresh = forceRefresh
    }

    func showTutorial(){
        if let parentVC = parent as? HomeViewController {
            parentVC.showTutorial()
        }
    }
    
    override func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        if drawer.drawerPosition == .open {
            backgroundDimmingColor = .systemBackground
            backgroundDimmingOpacity = 1.0
            incidentDrawerDelegate?.incidentListExpanded(true)

            // change view button setup
            changeViewButton.isHidden = false
            changeViewButton.setTitle("View map", for: .normal)
            changeViewButton.setImage(FWImage.viewMapIcon, for: .normal)
        } else if drawer.drawerPosition == .closed {
            backgroundDimmingColor = UIColor.black.withAlphaComponent(0.5)
            incidentDrawerDelegate?.incidentListExpanded(false)

            // change view button setup
            changeViewButton.isHidden = false
            changeViewButton.setTitle("View list", for: .normal)
            changeViewButton.setImage(FWImage.menuIconRed, for: .normal)
        } else {
            backgroundDimmingColor = UIColor.black.withAlphaComponent(0.5)
            incidentDrawerDelegate?.incidentListExpanded(false)
            changeViewButton.isHidden = true
        }
    }

    @IBAction func changeViewButtonTapped(_ sender: UIButton) {
        let isOpen = self.drawerPosition == .open
        let newPosition: PulleyPosition = isOpen ? .closed : .open
        self.setDrawerPosition(position: newPosition, animated: true)
    }
}

extension IncidentHomeViewController: IncidentsViewViewDelegate {
    func incidentDataLoaded() {
        hideLoader()
        if let contentVC, let incidentsViewModel, !incidentsViewModel.markersList.isEmpty {
            contentVC.markersList = incidentsViewModel.markersList
        }

        if let drawerVC, let incidentsViewModel, !incidentsViewModel.items.isEmpty {
            drawerVC.items = incidentsViewModel.items
            drawerVC.totalPages = incidentsViewModel.totalPages
            drawerVC.forceRefresh = forceRefresh
            self.forceRefresh = false // Reset force refresh
        }
    }

    func noIncidentData() {
        hideLoader()
        if let contentVC, let drawerVC {
            contentVC.markersList = []
            drawerVC.items = []
            drawerVC.totalPages = 0
        }
    }

    func error(message: String) {
        hideLoader()
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel) { _ in
            self.coordinator?.popView()
        }])
    }

    func tokenExpired() {
        appCoordinator?.backToParentCoordinator()
    }
}

extension IncidentHomeViewController: IncidentsListViewDelegate {
    func loadNextPage() {
        paginationHandler.loadNextPage()
    }

    func filterUpdate() {
        fetchIncidents()
    }
}
