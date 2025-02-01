//
//  MyAccountViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 06/12/24.
//

import UIKit

class MyAccountViewController: UIViewController, SubscriptionManagerDelegate {
    weak var appCoordinator: AppCoordinator?
    var coordinator: HomeCoordinator?

    @IBOutlet weak var profileImageView: FWRoundedImageView!
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
        
        if UserDefaults.standard.bool(forKey: "isPremiumUser"){
            let premiumStatus = String.init(format: "%@ | Premium User", nameLabel.text ?? "")
            nameLabel.text = premiumStatus
        }

        if let profileImage = UserDefaults.standard.string(forKey: "profile_image"),
            let imageUrl = URL(string: profileImage) {
            profileImageView.loadImage(from: imageUrl)
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
        clearUserDefaults()
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

    @IBAction func premiumButtonTapAction(_ sender: UIButton) {
        SubscriptionManager.shared.delegate = self
        SubscriptionManager.shared.purchaseMyProduct()
    }
    
    func purchaseTransactionCompleted(success: Bool) {
        if success {
            showAlertMessage("Your premium scubscription is Success!")
        }else{
            showAlertMessage("Purchase failed, please try again!")
        }
    }
    
    fileprivate func showAlertMessage(_ errorMessage: String, action: (() -> Void)? = nil) {
        showAlert(
            title: "",
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Ok"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }
    
    
    func clearUserDefaults(){
        ["user_id", "name", "email", "token", "profile_image"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        UserDefaults.standard.synchronize()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> MyAccountViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MyAccountViewController") as! MyAccountViewController
        return viewController
    }

}
