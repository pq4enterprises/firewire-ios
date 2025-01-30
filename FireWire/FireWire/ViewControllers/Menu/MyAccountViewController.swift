//
//  MyAccountViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 06/12/24.
//

import UIKit

class MyAccountViewController: UIViewController {
    weak var appCoordinator: AppCoordinator?
    var coordinator: HomeCoordinator?

    @IBOutlet weak var updateProfileView: UIStackView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var logoutView: UIStackView!
    @IBOutlet weak var termsStackView: UIStackView!
    @IBOutlet weak var privacyPolicyStackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    func setupUI() {
        if let name = UserDefaults.standard.string(forKey: "name"),
            let email = UserDefaults.standard.string(forKey: "email") {
            nameLabel.text = name
            emailLabel.text = email
        }
    }

    func setupActions(){
        let logoutViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(logoutViewTap))
        logoutView.isUserInteractionEnabled = true
        logoutView.addGestureRecognizer(logoutViewTapGesture)

        let termsTapGesture = UITapGestureRecognizer(target: self, action: #selector(termsViewTap))
        termsStackView.isUserInteractionEnabled = true
        termsStackView.addGestureRecognizer(termsTapGesture)

        let privacyPolicyTapGesture = UITapGestureRecognizer(target: self, action: #selector(privacyPolicyViewTap))
        privacyPolicyStackView.isUserInteractionEnabled = true
        privacyPolicyStackView.addGestureRecognizer(privacyPolicyTapGesture)

        let updateProfileTapGesture = UITapGestureRecognizer(target: self, action: #selector(updateProfileViewTap))
        updateProfileView.isUserInteractionEnabled = true
        updateProfileView.addGestureRecognizer(updateProfileTapGesture)
    }

    @objc func logoutViewTap() {
        self.appCoordinator?.backToParentCoordinator()
    }

    @objc func termsViewTap() {
        self.coordinator?.openURL(APIEndpoints.termsAndConditionUrl)
    }

    @objc func privacyPolicyViewTap() {
        self.coordinator?.openURL(APIEndpoints.privacyPolicyUrl)
    }

    @objc func updateProfileViewTap() {
        self.coordinator?.navigateToUpdateProfile()
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        appCoordinator?.popView()
    }
    
    // A convenience method to instantiate from the storyboard
    static func instantiate() -> MyAccountViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MyAccountViewController") as! MyAccountViewController
        return viewController
    }

}
