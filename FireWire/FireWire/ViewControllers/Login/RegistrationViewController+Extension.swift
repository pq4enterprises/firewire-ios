//
//  RegistrationViewController+Extension.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/06/26.
//

import UIKit

extension RegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let updatedText: String

        if let textRange = Range(range, in: currentText) {
            updatedText = currentText.replacingCharacters(in: textRange, with: string)
        } else {
            // Secure text fields can occasionally report a range that doesn't map cleanly to Swift String indices.
            let nsText = currentText as NSString
            if range.location <= nsText.length, range.location + range.length <= nsText.length {
                updatedText = nsText.replacingCharacters(in: range, with: string)
            } else {
                updatedText = currentText + string
            }
        }

        if textField == phoneTextField {
            if !string.isEmpty {
                let allowedCharacters = CharacterSet.decimalDigits
                let characterSet = CharacterSet(charactersIn: string)
                if !allowedCharacters.isSuperset(of: characterSet) {
                    return false
                }
            }
            return updatedText.count <= 15
        }

        if textField == passwordTextField || textField == confirmPasswordTextField {
            return !string.contains(" ")
        }

        if textField == firstNameTextField || textField == lastNameTextField {
            return updatedText.count <= 30
        }

        return true
    }
}

extension RegistrationViewController: RegistrationViewModelDelegate {
    func registrationSuccess() {
        hideLoader()
        showAlert(title: "", message: "New user registered", actions: [UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
            self.coordinator?.popView()
        })])
    }

    func registrationFail(errorMessage: String) {
        hideLoader()
        showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
    }

    func loginSuccess() {
        hideLoader()
        coordinator?.navigateToSelectArea()
    }

    func loginFailed(errorMessage: String) {
        hideLoader()
        showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
    }
}
