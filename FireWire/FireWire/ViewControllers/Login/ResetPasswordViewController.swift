//
//  ResetPasswordViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//  Rebuilt on FireWireTheme (2026 auth redesign): step 3 of 3 of the reset flow.
//

import UIKit

class ResetPasswordViewController: FWAuthScreenController, UITextFieldDelegate {
    var coordinator: LoginCoordinator?
    var resetToken: String?

    override var analyticsScreenName: String? { "Forgot Password" }

    private let passwordField = FWAuthField(caption: "New password", placeholder: "At least 8 characters", kind: .newPassword)
    private let confirmPasswordField = FWAuthField(caption: "Confirm new password", placeholder: "Re-enter password", kind: .newPassword)
    private let banner = FWBanner()
    private let saveButton = FWPrimaryButton(title: "Save new password")

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
    }

    private func buildLayout() {
        installTopBar(title: "Reset password") { [weak self] in self?.coordinator?.popView() }

        let form = UIStackView()
        form.axis = .vertical
        form.isLayoutMarginsRelativeArrangement = true
        form.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 20, trailing: 12)

        form.addArrangedSubview(FWAuthStepHeader(step: 3, title: "New password"))
        form.setCustomSpacing(12, after: form.arrangedSubviews.last!)

        let card = FWAuthCard()
        card.stack.addArrangedSubview(passwordField)
        let hint = FWAuthLabel.body("At least 8 characters.", color: FireWireTheme.muted)
        hint.font = FWAuthFont.caption
        card.stack.addArrangedSubview(hint)
        card.stack.setCustomSpacing(6, after: passwordField)
        card.stack.addArrangedSubview(confirmPasswordField)
        card.stack.addArrangedSubview(banner)
        form.addArrangedSubview(card)
        form.setCustomSpacing(16, after: card)

        saveButton.addTarget(self, action: #selector(submitButton), for: .touchUpInside)
        form.addArrangedSubview(saveButton)
        content.addArrangedSubview(form)

        [passwordField, confirmPasswordField].forEach {
            $0.textField.delegate = self
            $0.textField.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
        }
        passwordField.textField.returnKeyType = .next
        confirmPasswordField.textField.returnKeyType = .done
    }

    @objc private func editingChanged(_ textField: UITextField) {
        if textField === passwordField.textField { passwordField.setError(nil) }
        if textField === confirmPasswordField.textField { confirmPasswordField.setError(nil) }
        banner.hide()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === passwordField.textField {
            confirmPasswordField.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            submitButton()
        }
        return true
    }

    @objc func submitButton() {
        view.endEditing(true)
        banner.hide()

        let newPassword = passwordField.textField.text ?? ""
        let confirmPassword = confirmPasswordField.textField.text ?? ""

        let passwordError = FWAuthValidation.passwordError(newPassword)
        passwordField.setError(passwordError)
        var confirmError: String?
        if confirmPassword.isEmpty {
            confirmError = "Confirm your new password."
        } else if newPassword != confirmPassword {
            confirmError = "Passwords don’t match."
        }
        confirmPasswordField.setError(confirmError)
        guard passwordError == nil, confirmError == nil else { return }

        guard let resetToken = resetToken else {
            banner.show(.CommonError.techError, style: .error)
            return
        }

        showLoader()
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.resetPassword,
            payload: APIPayload.resetPassword(resetToken: resetToken, password: newPassword, confirmPassword: confirmPassword).toDictionary(),
            expect: SuccessResponseModel.self
        ) { [weak self] response, _, error in

            self?.hideLoader()
            if let errorMessage = error {
                self?.banner.show(FWAuthValidation.friendly(errorMessage), style: .error)
                return
            }

            guard let apiResponse = response else {
                self?.banner.show(.CommonError.techError, style: .error)
                return
            }

            if let response = apiResponse as? SuccessResponseModel {
                if response.code.lowercased() == "success" {
                    LoginViewController.pendingSuccessNotice = "Password updated. Sign in with your new password."
                    self?.coordinator?.popToRootView()
                } else {
                    self?.banner.show(response.message.isEmpty ? .CommonError.techError : response.message, style: .error)
                }
            }
        }
    }

    // Kept so existing call sites keep compiling; the screen is now built in code.
    static func instantiate() -> ResetPasswordViewController {
        return ResetPasswordViewController()
    }
}
