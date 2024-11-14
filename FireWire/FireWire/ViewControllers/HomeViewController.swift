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

    var mapViewController: MapViewController?
    var newsViewController: NewsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func setupView() {
        mapViewController = MapViewController()
        newsViewController = NewsViewController()

        switchToViewController(at: 0)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.layer.cornerRadius = 20
        segmentControl.layer.masksToBounds = true
    }


    @IBAction func switchViewAction(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        switchToViewController(at: selectedIndex)
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
        case 1:
            selectedViewController = newsViewController!
        default:
            return
        }

        // Add the new child view controller
        addChild(selectedViewController)
        selectedViewController.view.frame = viewContainer.bounds
        viewContainer.addSubview(selectedViewController.view)
        selectedViewController.didMove(toParent: self)
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */

}
