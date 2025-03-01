//
//  MyAccountViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 06/12/24.
//

import StoreKit
import UIKit

protocol MyAccountViewDelegate: AnyObject {
    func success(message: String)
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
    @IBOutlet weak var premiumInfoTitle: UILabel!
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
        setupActions()

        viewModel = MyAccountViewModel()
        viewModel?.delegate = self
    }

    func setupUI() {
        if let name = UserDefaults.standard.string(forKey: "name"),
           let email = UserDefaults.standard.string(forKey: "email")
        {
            nameLabel.text = name
            emailLabel.text = email
        }

        if UserDefaults.standard.bool(forKey: "isPremiumUser") {
            premiumInfoTitle.text = .PremiumDetails.premiumAccount
            getPremiumButton.isHidden = true
        }else{
            premiumInfoTitle.text = .PremiumDetails.title
            getPremiumButton.isHidden = false
        }

        if let profileImage = UserDefaults.standard.string(forKey: "profile_image"),
           let imageUrl = URL(string: profileImage)
        {
            profileImageView.loadImage(from: imageUrl)
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
        clearUserDefaults()
        appCoordinator?.backToParentCoordinator()
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
                // self.showAlertMessage("Your premium scubscription is Success!")
                self.viewModel?.submitPayment(transaction: transaction)
            } else {
                self.showAlertMessage("Purchase failed, please try again!")
            }
        }
    }

    func success(message: String) {
        showAlertMessage(message)
    }

    fileprivate func showAlertMessage(_ errorMessage: String, action: (() -> Void)? = nil) {
        showAlert(
            title: "",
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Ok"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }

    func clearUserDefaults() {
        for item in ["user_id", "name", "email", "token", "profile_image"] {
            UserDefaults.standard.removeObject(forKey: item)
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
