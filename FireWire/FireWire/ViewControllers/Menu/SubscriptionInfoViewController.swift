//
//  SubscriptionInfoViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 06/03/25.
//

import StoreKit
import UIKit

class SubscriptionInfoViewController: UIViewController, SubscriptionManagerDelegate {
    @IBOutlet var termsStackView: UIStackView!
    @IBOutlet var privacyPolicyStackView: UIStackView!

    var coordinator: HomeCoordinator?
    var viewModel: MyAccountViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await SubscriptionManager.shared.fetchProducts()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel = MyAccountViewModel()
        viewModel?.delegate = self

        setupActions()
    }

    func setupActions() {
        let termsTapGesture = UITapGestureRecognizer(target: self, action: #selector(termsViewTap))
        termsStackView.isUserInteractionEnabled = true
        termsStackView.addGestureRecognizer(termsTapGesture)

        let privacyPolicyTapGesture = UITapGestureRecognizer(target: self, action: #selector(privacyPolicyViewTap))
        privacyPolicyStackView.isUserInteractionEnabled = true
        privacyPolicyStackView.addGestureRecognizer(privacyPolicyTapGesture)
    }

    @objc func termsViewTap() {
        coordinator?.openURL(APIEndpoints.termsAndConditionUrl)
    }

    @objc func privacyPolicyViewTap() {
        coordinator?.openURL(APIEndpoints.privacyPolicyUrl)
    }

    @IBAction func closeButtonTap(_ sender: UIButton) {
        dismiss(animated: true)
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

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> SubscriptionInfoViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "SubscriptionInfoViewController") as! SubscriptionInfoViewController
        return viewController
    }
}

extension SubscriptionInfoViewController: MyAccountViewDelegate {
    func success(dataLoaded userData: UserProfileData, message: String) {
        hideLoader()
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
            self.dismiss(animated: true)
        })])
    }
    
    func failure(message: String) {
        hideLoader()
        showAlert(title: "", message: message, actions: [UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
            self.dismiss(animated: true)
        })])
    }
}
