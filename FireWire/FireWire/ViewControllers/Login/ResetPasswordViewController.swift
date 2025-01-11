//
//  ResetPasswordViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import UIKit

class ResetPasswordViewController: UIViewController {
    @IBOutlet var passwordTextField: FWTextField!

    var coordinator: LoginCoordinator?
    var resetToken: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    @IBAction func submitButton(_ sender: UIButton) {
        showLoader()
        guard let newPassword = passwordTextField.text, !newPassword.isEmpty, let resetToken = resetToken else {
            hideLoader()
            showAlertMessage("Please enter valid password")
            return
        }

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.resetPassword,
            payload: APIPayload.resetPassword(resetToken: resetToken, password: newPassword).toDictionary(),
            expect: SuccessResponseModel.self
        ) { [weak self] response, _, _ in

            self?.hideLoader()
            guard let apiResponse = response else {
                self?.showAlertMessage("Technical error, please try again!")
                return
            }

            if let response = apiResponse as? SuccessResponseModel {
                if response.code.lowercased() == "success" {
                    self?.showToast(message: "Reset password success")
                    self?.coordinator?.popToRootView()
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
    static func instantiate() -> ResetPasswordViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ResetPasswordViewController") as! ResetPasswordViewController
        return viewController
    }
}
