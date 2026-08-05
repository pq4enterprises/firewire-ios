//
//  HomeViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import AppTrackingTransparency
import MaterialShowcase
import UIKit

class HomeViewController: UIViewController {
    @IBOutlet var viewContainer: UIView!
    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var feedsButton: UIButton!
    @IBOutlet var headerView: UIView!
    @IBOutlet var reloadButton: UIButton!

    var coordinator: HomeCoordinator?
    var appCoordinator: AppCoordinator?

    var incidentHomeVC: IncidentHomeViewController?
    // var incidentsViewController: IncidentsViewController?
    var newsViewController: NewsListViewController?

    var isIncidentListExpanded: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ATTrackingManager.requestTrackingAuthorization { _ in }
    }

    func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        styleHeader()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        incidentHomeVC = storyboard.instantiateViewController(withIdentifier: "IncidentHomeViewController") as? IncidentHomeViewController
        incidentHomeVC?.drawerTopInset = 60.0
        incidentHomeVC?.initialDrawerPosition = .partiallyRevealed
        incidentHomeVC?.coordinator = coordinator
        incidentHomeVC?.appCoordinator = appCoordinator
        incidentHomeVC?.incidentDrawerDelegate = self

//        incidentsViewController = IncidentsViewController(viewModel: IncidentsViewModel())
//        incidentsViewController?.coordinator = coordinator
//        incidentsViewController?.appCoordinator = appCoordinator
//        incidentsViewController?.incidentListExpanded = { listExpanded in
//            self.isIncidentListExpanded = listExpanded
//            self.updateUI(listExpanded)
//        }

        newsViewController = NewsListViewController(viewModel: NewsListViewModel())
        newsViewController?.coordinator = coordinator

        switchToViewController(at: 0)
        segmentControl.selectedSegmentIndex = 0
    }

    /// New design system: solid surface header with hairline, WIRE/NEWS
    /// segmented pill, themed line icons for menu / reload / scanner.
    private func styleHeader() {
        view.backgroundColor = FireWireTheme.background
        headerView.backgroundColor = FireWireTheme.surface

        let hairline = UIView()
        hairline.backgroundColor = FireWireTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(hairline)
        NSLayoutConstraint.activate([
            hairline.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),
        ])

        menuButton.setImage(
            UIImage(systemName: "line.3.horizontal",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)),
            for: .normal)
        menuButton.tintColor = FireWireTheme.text

        reloadButton.setImage(
            UIImage(systemName: "arrow.clockwise",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)),
            for: .normal)
        reloadButton.tintColor = FireWireTheme.text

        feedsButton.setImage(
            UIImage(systemName: "radio",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)),
            for: .normal)
        feedsButton.tintColor = FireWireTheme.text

        segmentControl.setTitle("WIRE", forSegmentAt: 0)
        segmentControl.setTitle("NEWS", forSegmentAt: 1)
        segmentControl.backgroundColor = FireWireTheme.surface2
        segmentControl.selectedSegmentTintColor = FireWireTheme.surface
        segmentControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: FireWireTheme.muted,
            .kern: 0.6,
        ], for: .normal)
        segmentControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 13, weight: .heavy),
            .foregroundColor: FireWireTheme.text,
            .kern: 0.6,
        ], for: .selected)
        segmentControl.layer.cornerRadius = 12
        segmentControl.layer.masksToBounds = true
    }

    func updateUI(_ listExpanded: Bool) {
        // Header is always solid surface in the new design system — nothing
        // to swap when the incident list expands/collapses over the map.
    }

    @IBAction func switchViewAction(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        switchToViewController(at: selectedIndex)
    }

    @IBAction func menuButtonTap(_ sender: UIButton) {
        coordinator?.navigateToMenu()
    }

    @IBAction func feedsButtonTap(_ sender: UIButton) {
        coordinator?.navigateToFeeds()
    }

    @IBAction func reloadButtonTap(_ sender: UIButton) {
        if let incidentHomeVC {
            incidentHomeVC.fetchIncidents(forceRefresh: true)
        }
    }

    @IBAction func changeViewButtonTap(_ sender: UIButton) {
//        isIncidentListExpanded == true
//            ? incidentsViewController?.expandMap()
//            : incidentsViewController?.expandList()
    }

    func switchToViewController(at index: Int) {
        // Remove the currently visible child view controller
        for child in children {
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        // Add the selected child view controller
        let selectedViewController: UIViewController

        switch index {
        case 0:
            selectedViewController = incidentHomeVC!
            reloadButton.isHidden = false
        case 1:
            selectedViewController = newsViewController!
            reloadButton.isHidden = true
        default:
            return
        }

        // Add the new child view controller
        addChild(selectedViewController)
        selectedViewController.view.frame = viewContainer.bounds
        viewContainer.addSubview(selectedViewController.view)
        selectedViewController.didMove(toParent: self)
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> HomeViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        return viewController
    }
}

extension HomeViewController: MaterialShowcaseDelegate {
    func showTutorial() {
        let showCase1 = createMaterialShowcase(primaryText: "Radio", secondaryText: "Listen to Scanner Feeds", targetView: feedsButton)

        var showCase2: MaterialShowcase?
        if let segmentView = segmentView(from: segmentControl, at: 1) {
            showCase2 = createMaterialShowcase(primaryText: "News", secondaryText: "News, Updates, Articles from Fire Wire", targetView: segmentView)
        }

        let showCase3 = createMaterialShowcase(primaryText: "Edit Profile", secondaryText: "My Account -> Update Profile", targetView: menuButton)
        let showCase4 = createMaterialShowcase(primaryText: "Notification", secondaryText: "Areas & Alerts", targetView: menuButton)
        let showCase5 = createMaterialShowcase(primaryText: "Submit A Tip", secondaryText: "Click Menu option to Submit A Tip", targetView: menuButton)

        showCase1.delegate = self

        if let showCase2 {
            showCase2.delegate = self
        }

        showCase3.delegate = self
        showCase4.delegate = self
        showCase5.delegate = self

        ShowcaseManager.shared.startSequence([showCase1, showCase2!, showCase3, showCase4, showCase5]) {
            if let drawerVC = self.incidentHomeVC?.drawerContentViewController as? IncidentListViewController {
                drawerVC.showTutorial()
            }
        }
    }

    func segmentView(from segmentedControl: UISegmentedControl, at index: Int) -> UIView? {
        guard index < segmentedControl.numberOfSegments else { return nil }
        let segmentViews = segmentedControl.subviews.sorted { $0.frame.minX < $1.frame.minX }
        return segmentViews.reversed()[index]
    }

    func showCaseDidDismiss(showcase: MaterialShowcase, didTapTarget: Bool) {
        ShowcaseManager.shared.markNext()
    }
}

extension HomeViewController: IncidentDrawerDelegate {
    func incidentListExpanded(_ value: Bool) {
        updateUI(value)
    }
}
