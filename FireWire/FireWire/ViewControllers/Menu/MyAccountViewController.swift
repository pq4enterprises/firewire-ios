//
//  MyAccountViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 06/12/24.
//

import FirebaseAnalytics
import StoreKit
import UIKit

protocol EmailVerificationDelegate: AnyObject {
    func resendEmailOtp(status: Bool)
}

protocol MyAccountViewDelegate: AnyObject {
    func success(dataLoaded userData: UserProfileData, message: String)
    func failure(message: String)
}

class MyAccountViewController: UIViewController, SubscriptionManagerDelegate {
    weak var appCoordinator: AppCoordinator?
    var coordinator: HomeCoordinator?

    @IBOutlet var profileImageView: FWRoundedImageView!
    @IBOutlet var updateProfileView: UIStackView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet weak var verifyEmailLabel: FWPaddingLabel!
    @IBOutlet var logoutView: UIStackView!
    @IBOutlet var termsStackView: UIStackView!
    @IBOutlet var privacyPolicyStackView: UIStackView!
    @IBOutlet var restoreSubscriptionButton: UIButton!
    @IBOutlet var premiumInfoView: UIView!
    @IBOutlet var subscriptionInfoView: UIView!

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

        showLoader()
        viewModel = MyAccountViewModel()
        viewModel?.getUserProfile(forSubscription: false)
        viewModel?.delegate = self
        viewModel?.emailVerificationDelegate = self

        SubscriptionManager.shared.delegate = self
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
            premiumInfoView.isHidden = true
            subscriptionInfoView.isHidden = false
        } else {
            premiumInfoView.isHidden = false
            subscriptionInfoView.isHidden = true
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

        let verifyEmailTapGesture = UITapGestureRecognizer(target: self, action: #selector(verifyEmailViewTap))
        verifyEmailLabel.isUserInteractionEnabled = true
        verifyEmailLabel.addGestureRecognizer(verifyEmailTapGesture)
    }

    @objc func logoutViewTap() {
        showAlert(title: "Sign Out", message: "Are you sure you want to sign out?", actions: [UIAlertAction(title: "Sign Out", style: .default, handler: { _ in
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

    @objc func verifyEmailViewTap(){
        viewModel?.requestEmailVerification()
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        if let appCoordinator {
            appCoordinator.popView()
        } else if let coordinator {
            coordinator.popView()
        }
    }

    @IBAction func premiumButtonTapAction(_ sender: UIButton) {
        Analytics.logEvent("subscribe_button_tapped", parameters: [
            AnalyticsParameterScreenName: "ios_my_account"
        ])

        Task {
            await SubscriptionManager.shared.purchaseMyProduct()
        }
    }

    @IBAction func restoreSubscriptionTap(_ sender: UIButton) {
        Task {
            await SubscriptionManager.shared.restorePurchases()
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

extension MyAccountViewController: MyAccountViewDelegate, EmailVerificationDelegate {
    func resendEmailOtp(status: Bool) {
        if let email = FWUserDefaults().userEmail {
            coordinator?.navigateToOTPVerification(email: email, verificationType: .existingUser)
        }
    }
    
    func success(dataLoaded userData: UserProfileData, message: String) {
        hideLoader()

        updatePremiumInfo()

        if !message.isEmpty {
            showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
        }

        updateVerifyButton(isVerified: userData.emailVerified)
    }

    func failure(message: String) {
        hideLoader()

        if !message.isEmpty {
            showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
        }
    }

    func updateVerifyButton(isVerified: Bool) {
        verifyEmailLabel.layer.cornerRadius = 8
        verifyEmailLabel.layer.masksToBounds = true
        verifyEmailLabel.textAlignment = .center

        if isVerified {
            verifyEmailLabel.text = "✓ Verified Email"
            verifyEmailLabel.textColor = .systemGreen
            verifyEmailLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        } else {
            verifyEmailLabel.text = "Verify Email"
            verifyEmailLabel.textColor = .systemBlue
            verifyEmailLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        }
    }
}
