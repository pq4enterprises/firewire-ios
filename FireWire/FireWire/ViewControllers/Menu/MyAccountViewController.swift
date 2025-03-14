//
//  MyAccountViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 06/12/24.
//

import StoreKit
import UIKit

protocol MyAccountViewDelegate: AnyObject {
    func dataLoaded(status: Bool, message: String)
}

class MyAccountViewController: UIViewController, SubscriptionManagerDelegate, MyAccountViewDelegate {
    weak var appCoordinator: AppCoordinator?
    var coordinator: HomeCoordinator?

    @IBOutlet var profileImageView: FWRoundedImageView!
    @IBOutlet var updateProfileView: UIStackView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var logoutView: UIStackView!
    @IBOutlet var termsStackView: UIStackView!
    @IBOutlet var privacyPolicyStackView: UIStackView!
    @IBOutlet var premiumInfoTitle: UILabel!
    @IBOutlet var getPremiumButton: FWFilledButton!

    var viewModel: MyAccountViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await SubscriptionManager.shared.fetchProducts()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
        updatePremiumInfo()
        setupActions()

        viewModel = MyAccountViewModel()
        viewModel?.delegate = self
    }

    func setupUI() {
        if let name = FWUserDefaults().userName, let email = FWUserDefaults().userEmail {
            nameLabel.text = name
            emailLabel.text = email
        }

        if let profileImage = FWUserDefaults().userImage,
           let imageUrl = URL(string: profileImage)
        {
            profileImageView.loadImage(from: imageUrl)
        }
    }

    func updatePremiumInfo() {
        if FWUserDefaults().userRole == "basic_user" {
            premiumInfoTitle.text = .PremiumDetails.title
            getPremiumButton.isHidden = false
        } else {
            premiumInfoTitle.text = .PremiumDetails.premiumAccount
            getPremiumButton.isHidden = true
        }
    }

    func setupActions() {
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
        showAlert(title: "Sign Out", message: "Are you sure you want to sign out?", actions: [UIAlertAction(title: "Sign Out", style: .default, handler: { action in
            self.clearUserDefaults()
            self.appCoordinator?.backToParentCoordinator()
        })], cancel: true)

    }

    @objc func termsViewTap() {
        coordinator?.openURL(APIEndpoints.termsAndConditionUrl)
    }

    @objc func privacyPolicyViewTap() {
        coordinator?.openURL(APIEndpoints.privacyPolicyUrl)
    }

    @objc func updateProfileViewTap() {
        coordinator?.navigateToUpdateProfile()
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        appCoordinator?.popView()
    }

    @IBAction func premiumButtonTapAction(_ sender: UIButton) {
        SubscriptionManager.shared.delegate = self
        Task {
            await SubscriptionManager.shared.purchaseMyProduct()
        }
    }

    func purchaseTransactionCompleted(success: Bool, transaction: Transaction?) {
        DispatchQueue.main.async {
            if success {
                self.showLoader()
                self.viewModel?.submitPayment(transaction: transaction)
            } else {
                self.hideLoader()
                self.showAlert(title: "", message: "Purchase failed, please try again!", actions: [UIAlertAction(title: "Ok", style: .cancel)])
            }
        }
    }

    func dataLoaded(status: Bool, message: String) {
        hideLoader()
        if status {
            updatePremiumInfo()
        }
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
    }

    func clearUserDefaults() {
        FWUserDefaults.removeObjectForKey(key: .userIDKey)
        FWUserDefaults.removeObjectForKey(key: .userNameKey)
        FWUserDefaults.removeObjectForKey(key: .userEmailKey)
        FWUserDefaults.removeObjectForKey(key: .userTokenKey)
        FWUserDefaults.removeObjectForKey(key: .userImageKey)
        FWUserDefaults.removeObjectForKey(key: .userRoleKey)
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> MyAccountViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MyAccountViewController") as! MyAccountViewController
        return viewController
    }
}
