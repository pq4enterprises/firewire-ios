//
//  PersonalisationViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

class PersonalisationViewController: UIViewController {
    var coordinator: HomeCoordinator?
    
    @IBOutlet weak var feedAreasView: UIStackView!
    @IBOutlet weak var notificationView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
    }

    func setupActions(){
        let feedAreaGesture = UITapGestureRecognizer(target: self, action: #selector(feedAreaTap))
        feedAreasView.isUserInteractionEnabled = true
        feedAreasView.addGestureRecognizer(feedAreaGesture)

        let notificationGesture = UITapGestureRecognizer(target: self, action: #selector(notificationTap))
        notificationView.isUserInteractionEnabled = true
        notificationView.addGestureRecognizer(notificationGesture)
    }

    @objc func feedAreaTap() {
        coordinator?.navigateToFeedAreaListView()
    }

    @objc func notificationTap() {
        coordinator?.navigateToNotificationSettings()
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> PersonalisationViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "PersonalisationViewController") as! PersonalisationViewController
        return viewController
    }
}
