//
//  IncidentHomeViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 17/07/25.
//

import Pulley
import UIKit
import FirebaseAnalytics

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

        contentVC?.coordinator = coordinator

        incidentsViewModel = IncidentsViewModel()
        incidentsViewModel?.delegate = self

        paginationHandler = PaginationHandler(viewModel: incidentsViewModel!)

        styleUI()
    }

    /// New design system: rounded surface sheet and a red VIEW MAP/LIST pill.
    private func styleUI() {
        drawerCornerRadius = 22
        drawerBackgroundVisualEffectView = nil

        changeViewButton.isHidden = true
        changeViewButton.backgroundColor = FireWireTheme.red
        changeViewButton.tintColor = .white
        changeViewButton.setTitleColor(.white, for: .normal)
        changeViewButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .heavy)
        changeViewButton.setupShadow()
        changeViewButton.layer.shadowColor = FireWireTheme.red.cgColor
        changeViewButton.layer.shadowOpacity = 0.4
        view.bringSubviewToFront(changeViewButton)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "ios_incident_feed"
        ])

        showLoader()
        incidentsViewModel?.validateIfAreaSelected(forType: .area) { result, errorMessage  in
            self.hideLoader()

            if !result && errorMessage != "" {
                self.showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
            }else if !result && errorMessage == "" {
                 self.coordinator?.navigateToSelectArea()
            }else{
                self.fetchIncidents()
            }
        }
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
        let pinImage = UIImage(
            systemName: "mappin.and.ellipse",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        let listImage = UIImage(
            systemName: "list.bullet",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))

        if drawer.drawerPosition == .open {
            backgroundDimmingColor = FireWireTheme.background
            backgroundDimmingOpacity = 1.0
            incidentDrawerDelegate?.incidentListExpanded(true)

            // change view button setup
            changeViewButton.isHidden = false
            changeViewButton.setTitle("VIEW MAP", for: .normal)
            changeViewButton.setImage(pinImage, for: .normal)
        } else if drawer.drawerPosition == .closed {
            backgroundDimmingColor = UIColor.black.withAlphaComponent(0.5)
            incidentDrawerDelegate?.incidentListExpanded(false)

            // change view button setup
            changeViewButton.isHidden = false
            changeViewButton.setTitle("VIEW LIST", for: .normal)
            changeViewButton.setImage(listImage, for: .normal)
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
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
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
