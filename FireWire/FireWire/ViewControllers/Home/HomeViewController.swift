//
//  HomeViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var segmentControl: FWSegmentControl!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var feedsButton: UIButton!
    
    var coordinator: HomeCoordinator?
    var appCoordinator: AppCoordinator?
    var mapViewController: MapViewController?
    var newsViewController: NewsListViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func setupView() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        mapViewController = MapViewController()
        mapViewController?.appCoordinator = appCoordinator
        mapViewController?.coordinator = coordinator
        
        newsViewController = NewsListViewController(viewModel: NewsListViewModel())
        newsViewController?.coordinator = coordinator

        switchToViewController(at: 0)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.layer.cornerRadius = 20
        segmentControl.layer.masksToBounds = true
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
            selectedViewController = mapViewController!

            menuButton.setImage(FWImage.menuIconWhite, for: .normal)
            feedsButton.setImage(FWImage.alertIconWhite, for: .normal)
        case 1:
            selectedViewController = newsViewController!

            menuButton.setImage(FWImage.menuIcon, for: .normal)
            feedsButton.setImage(FWImage.alertIcon, for: .normal)
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
