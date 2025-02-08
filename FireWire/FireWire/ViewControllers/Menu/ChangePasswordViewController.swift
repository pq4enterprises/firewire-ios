//
//  ChangePasswordViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 08/02/25.
//

import UIKit

class ChangePasswordViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var currentPasswordTextField: FWTextField!
    @IBOutlet weak var newPasswordTextField: FWTextField!
    @IBOutlet weak var confirmPasswordTextField: FWTextField!

    var coordinator: HomeCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        currentPasswordTextField.addRightIcon(UIImage(named: "eye_icon")!) { [weak self] in
            guard let self else { return }
            self.togglePasswordVisibility(self.currentPasswordTextField)
        }

        newPasswordTextField.addRightIcon(UIImage(named: "eye_icon")!) { [weak self] in
            guard let self else { return }
            self.togglePasswordVisibility(self.newPasswordTextField)
        }

        confirmPasswordTextField.addRightIcon(UIImage(named: "eye_icon")!) { [weak self] in
            guard let self else { return }
            self.togglePasswordVisibility(self.confirmPasswordTextField)
        }

    }

    func togglePasswordVisibility(_ textField: UITextField) {
        textField.isSecureTextEntry.toggle()
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    @IBAction func submitButton(_ sender: UIButton) {
        showLoader()
        guard let newPassword = newPasswordTextField.text, !newPassword.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty,
              let oldPassword = currentPasswordTextField.text, !oldPassword.isEmpty
        else {
            hideLoader()
            showAlertMessage("Please enter valid password")
            return
        }

        if newPassword != confirmPassword {
            hideLoader()
            showAlertMessage("One of the password is not matching")
            return
        }

        let requestModel = UpdatePasswordRequestModel(oldPassword: oldPassword, newPassword: newPassword, confirmPassword: confirmPassword)

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.updatePassword,
            payload: APIPayload.updatePassword(requestModel).toDictionary(),
            expect: SuccessResponseModel.self
        ) { [weak self] response, _, _ in

            self?.hideLoader()
            guard let apiResponse = response as? SuccessResponseModel else {
                let errorMessage = (response == nil) ? "Invalid request" : "Unexpected response format"
                self?.showAlertMessage(errorMessage)
                return
            }

            if apiResponse.code != "success" {
                self?.showAlertMessage(apiResponse.message)
                return
            }

            if apiResponse.code.lowercased() == "success" {
                self?.showToast(message: "Update password success")
                self?.coordinator?.popView()
            } else {
                self?.showAlertMessage("Technical error, please try again!")
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
    static func instantiate() -> ChangePasswordViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ChangePasswordViewController") as! ChangePasswordViewController
        return viewController
    }

}
