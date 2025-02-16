//
//  HomeViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet var viewContainer: UIView!
    @IBOutlet var segmentControl: FWSegmentControl!
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var feedsButton: UIButton!
    @IBOutlet var headerView: UIView!
    @IBOutlet var changeViewButton: FWRoundedButton!

    var coordinator: HomeCoordinator?
    var appCoordinator: AppCoordinator?
    // var mapViewController: MapViewController?
    var incidentsViewController: IncidentsViewController?
    var newsViewController: NewsListViewController?

    var isIncidentListExpanded: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        // mapViewController = MapViewController()
        // mapViewController?.appCoordinator = appCoordinator
        // mapViewController?.coordinator = coordinator

        incidentsViewController = IncidentsViewController(viewModel: IncidentsViewModel())
        incidentsViewController?.coordinator = coordinator
        incidentsViewController?.appCoordinator = appCoordinator
        incidentsViewController?.incidentListExpanded = { listExpanded in
            self.isIncidentListExpanded = listExpanded
            self.updateUI(listExpanded)
        }

        newsViewController = NewsListViewController(viewModel: NewsListViewModel())
        newsViewController?.coordinator = coordinator

        switchToViewController(at: 0)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.layer.cornerRadius = 20
        segmentControl.layer.masksToBounds = true

        changeViewButton.setupShadow()
        changeViewButton.isHidden = true
    }

    func updateUI(_ listExpanded: Bool) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.headerView.backgroundColor = .white
            self.menuButton.setImage(FWImage.menuIcon, for: .normal)
            self.feedsButton.setImage(FWImage.alertIcon, for: .normal)
            self.view.layoutIfNeeded()
        }, completion: nil)

        changeViewButton.isHidden = false

        if listExpanded {
            changeViewButton.setTitle("View map", for: .normal)
            changeViewButton.setImage(FWImage.viewMapIcon, for: .normal)
        } else {
            changeViewButton.setTitle("View list", for: .normal)
            changeViewButton.setImage(FWImage.menuIconRed, for: .normal)
        }
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

    @IBAction func changeViewButtonTap(_ sender: UIButton) {
        isIncidentListExpanded == true
            ? incidentsViewController?.expandMap()
            : incidentsViewController?.expandList()
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
            // selectedViewController = mapViewController!
            selectedViewController = incidentsViewController!

            menuButton.setImage(FWImage.menuIconWhite, for: .normal)
            feedsButton.setImage(FWImage.alertIconWhite, for: .normal)
            changeViewButton.isHidden = !(isIncidentListExpanded ?? true)
        case 1:
            selectedViewController = newsViewController!

            menuButton.setImage(FWImage.menuIcon, for: .normal)
            feedsButton.setImage(FWImage.alertIcon, for: .normal)
            changeViewButton.isHidden = true
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
