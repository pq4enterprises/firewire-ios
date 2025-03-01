//
//  ForgotPasswordViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import UIKit

class ForgotPasswordViewController: UIViewController {
    @IBOutlet var emailTextField: FWTextField!

    var coordinator: LoginCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    @IBAction func confirmButtonTap(_ sender: UIButton) {
        showLoader()
        guard let email = emailTextField.text, !email.isEmpty, email.isValidEmail() else {
            hideLoader()
            showAlertMessage("Please enter valid email")
            return
        }

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.forgotPassword,
            payload: APIPayload.forgotPassword(email: email).toDictionary(),
            expect: ForgotPasswordResponseModel.self
        ) { [weak self] response, _, _ in

            self?.hideLoader()
            guard let apiResponse = response else {
                self?.showAlertMessage("Technical error, please try again!")
                return
            }

            if let response = apiResponse as? ForgotPasswordResponseModel {
                if response.code.lowercased() == "success" {
                    self?.coordinator?.navigateToOtpVerification(email: email)
                } else {
                    self?.showAlertMessage(response.message)
                }
            }
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
    static func instantiate() -> ForgotPasswordViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ForgotPasswordViewController") as! ForgotPasswordViewController
        return viewController
    }
}
