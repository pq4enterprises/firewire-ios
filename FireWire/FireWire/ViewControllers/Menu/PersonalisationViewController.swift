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
    @IBOutlet weak var notificationSoundsView: UIStackView!
    
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

        let notificationSoundsGesture = UITapGestureRecognizer(target: self, action: #selector(notificationSoundsTap))
        notificationSoundsView.isUserInteractionEnabled = true
        notificationSoundsView.addGestureRecognizer(notificationSoundsGesture)
    }

    @objc func feedAreaTap() {
        coordinator?.navigateToFeedAreaListView()
    }

    @objc func notificationTap() {
        guard unlockPremiumFeatureIfValid() == false else { return }
        coordinator?.navigateToNotificationSettings()
    }

    @objc func notificationSoundsTap() {
        coordinator?.navigateToNotificationSounds()
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    func unlockPremiumFeatureIfValid() -> Bool {
        if FWUserDefaults().userRole == "basic_user" {
            coordinator?.navigateToSubscriptionInfo()
            return true
        }
        return false
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> PersonalisationViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "PersonalisationViewController") as! PersonalisationViewController
        return viewController
    }
}
