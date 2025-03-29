//
//  ChangePasswordViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 08/02/25.
//

import UIKit

class ChangePasswordViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var currentPasswordTextField: FWTextField!
    @IBOutlet var newPasswordTextField: FWTextField!
    @IBOutlet var confirmPasswordTextField: FWTextField!

    var coordinator: HomeCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        [currentPasswordTextField, newPasswordTextField, confirmPasswordTextField].forEach { $0.delegate = self }

        currentPasswordTextField.addRightIcon(FWImage.hidePasswordIcon!) { [weak self] in
            guard let self else { return }
            self.togglePasswordVisibility(self.currentPasswordTextField)
        }

        newPasswordTextField.addRightIcon(FWImage.hidePasswordIcon!) { [weak self] in
            guard let self else { return }
            self.togglePasswordVisibility(self.newPasswordTextField)
        }

        confirmPasswordTextField.addRightIcon(FWImage.hidePasswordIcon!) { [weak self] in
            guard let self else { return }
            self.togglePasswordVisibility(self.confirmPasswordTextField)
        }
    }

    func togglePasswordVisibility(_ textField: UITextField) {
        textField.isSecureTextEntry.toggle()
        let icon = textField.isSecureTextEntry ? FWImage.hidePasswordIcon! : FWImage.showPasswordIcon!

        if let button = textField.rightView as? UIButton {
            button.setImage(icon, for: .normal)
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Prevent spaces
        if string.contains(" ") {
            return false
        }

        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        return newLength <= 15
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
            showAlert(title: "", message: "Please enter valid password", actions: [UIAlertAction(title: "Ok", style: .cancel)])
            return
        }

        if newPassword.count < 8 && confirmPassword.count < 8 {
            hideLoader()
            showAlert(title: "", message: "Password should be at least 8 character long", actions: [UIAlertAction(title: "Ok", style: .cancel)])
            return
        }

        if newPassword != confirmPassword {
            hideLoader()
            showAlert(title: "", message: "One of the password is not matching", actions: [UIAlertAction(title: "Ok", style: .cancel)])
            return
        }

        let requestModel = UpdatePasswordRequestModel(oldPassword: oldPassword, newPassword: newPassword, confirmPassword: confirmPassword)

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.updatePassword,
            payload: APIPayload.updatePassword(requestModel).toDictionary(),
            expect: SuccessResponseModel.self
        ) { [weak self] response, _, error in

            self?.hideLoader()
            if let errorMessage = error {
                self?.showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                return
            }

            guard let apiResponse = response as? SuccessResponseModel else {
                let errorMessage = (response == nil) ? "Invalid request" : "Unexpected response format"
                self?.showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                return
            }

            if apiResponse.code != "success" {
                self?.showAlert(title: "", message: apiResponse.message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                return
            }

            if apiResponse.code.lowercased() == "success" {
                self?.showAlert(title: "", message: "Your password has been successfully updated", actions: [UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
                    self?.coordinator?.popView()
                })])

            } else {
                self?.showAlert(title: "", message: "Technical error, please try again!", actions: [UIAlertAction(title: "Ok", style: .cancel)])
            }
        }
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> ChangePasswordViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ChangePasswordViewController") as! ChangePasswordViewController
        return viewController
    }
}
