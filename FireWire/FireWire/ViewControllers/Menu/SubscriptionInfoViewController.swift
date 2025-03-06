//
//  SubscriptionInfoViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 06/03/25.
//

import StoreKit
import UIKit

class SubscriptionInfoViewController: UIViewController, SubscriptionManagerDelegate, MyAccountViewDelegate {
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
                self.showAlertMessage("Purchase failed, please try again!")
            }
        }
    }

    func dataLoaded(status: Bool, message: String) {
        hideLoader()
        showAlertMessage(message){
            self.dismiss(animated: true)
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

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> SubscriptionInfoViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "SubscriptionInfoViewController") as! SubscriptionInfoViewController
        return viewController
    }
}
