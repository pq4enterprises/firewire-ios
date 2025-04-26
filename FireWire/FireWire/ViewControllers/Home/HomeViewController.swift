//
//  HomeViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet var viewContainer: UIView!
    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var feedsButton: UIButton!
    @IBOutlet var headerView: UIView!
    @IBOutlet weak var reloadButton: UIButton!

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
    }

    func updateUI(_ listExpanded: Bool) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            if listExpanded {
                self.headerView.backgroundColor = .systemBackground

                let isDarkMode = self.traitCollection.userInterfaceStyle == .dark
                self.menuButton.setImage(isDarkMode ? FWImage.menuIconWhite : FWImage.menuIcon, for: .normal)
                self.feedsButton.setImage(isDarkMode ? FWImage.alertIconWhite : FWImage.alertIcon, for: .normal)
                self.reloadButton.tintColor = isDarkMode ? .white : UIColor.label
            } else {
                self.headerView.backgroundColor = .clear
                self.menuButton.setImage(FWImage.menuIconWhite, for: .normal)
                self.feedsButton.setImage(FWImage.alertIconWhite, for: .normal)
                self.reloadButton.tintColor = .white
            }
            self.view.layoutSubviews()
        }, completion: nil)
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
        if let incidentsViewController {
            incidentsViewController.reloadIncidentsView()
        }
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
            selectedViewController = incidentsViewController!

            menuButton.setImage(FWImage.menuIconWhite, for: .normal)
            feedsButton.setImage(FWImage.alertIconWhite, for: .normal)
            reloadButton.isHidden = false
            updateUI(isIncidentListExpanded)
        case 1:
            selectedViewController = newsViewController!

            menuButton.setImage(FWImage.menuIcon, for: .normal)
            feedsButton.setImage(FWImage.alertIcon, for: .normal)
            reloadButton.isHidden = true
            updateUI(true)
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
