//
//  ResetPasswordViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import UIKit

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var passwordTextField: FWTextField!
    @IBOutlet var confirmPasswordTextField: FWTextField!

    var coordinator: LoginCoordinator?
    var resetToken: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        [passwordTextField, confirmPasswordTextField].forEach { $0.delegate = self }

        passwordTextField.addRightIcon(FWImage.hidePasswordIcon!) { [weak self] in
            guard let self else { return }
            self.togglePasswordVisibility(self.passwordTextField)
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
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length

        if string.contains(" ") {
            return false
        }

        return newLength <= 15
    }

    @IBAction func submitButton(_ sender: UIButton) {
        showLoader()
        guard let newPassword = passwordTextField.text, !newPassword.isEmpty, let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty, let resetToken = resetToken else {
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

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.resetPassword,
            payload: APIPayload.resetPassword(resetToken: resetToken, password: newPassword, confirmPassword: confirmPassword).toDictionary(),
            expect: SuccessResponseModel.self
        ) { [weak self] response, _, error in

            self?.hideLoader()
            if let errorMessage = error {
                self?.showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                return
            }

            guard let apiResponse = response else {
                self?.showAlert(title: "", message: .CommonError.techError, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                return
            }

            if let response = apiResponse as? SuccessResponseModel {
                if response.code.lowercased() == "success" {
                    self?.showAlert(title: "", message: "Reset password success", actions: [UIAlertAction(title: "Ok", style: .default, handler: { _ in
                        self?.coordinator?.popToRootView()
                    })])
                } else {
                    self?.showAlert(title: "", message: response.message.isEmpty ? .CommonError.techError : response.message, actions: [UIAlertAction(title: "Ok", style: .cancel)])
                }
            }
        }
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> ResetPasswordViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ResetPasswordViewController") as! ResetPasswordViewController
        return viewController
    }
}
