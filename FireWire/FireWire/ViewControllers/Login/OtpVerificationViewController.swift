//
//  OtpVerificationViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//  Rebuilt on FireWireTheme (2026 auth redesign): step 2 of 3 of the reset
//  flow. One 6-digit field (one-time-code autofill) replaces the six boxes.
//

import UIKit

class OtpVerificationViewController: FWAuthScreenController, UITextFieldDelegate {
    var coordinator: LoginCoordinator?
    var email: String?

    override var analyticsScreenName: String? { "Forgot Password" }

    private let codeField = FWAuthField(caption: "Verification code", placeholder: "••••••", kind: .code)
    private let resendControl = FWResendControl()
    private let banner = FWBanner()
    private let verifyButton = FWPrimaryButton(title: "Verify code")
    private let codeLength = 6
    private var isSubmitting = false

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        resendControl.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        codeField.textField.becomeFirstResponder()
    }

    private func buildLayout() {
        installTopBar(title: "Reset password") { [weak self] in self?.coordinator?.popView() }

        let form = UIStackView()
        form.axis = .vertical
        form.isLayoutMarginsRelativeArrangement = true
        form.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 20, trailing: 12)

        form.addArrangedSubview(FWAuthStepHeader(step: 2, title: "Enter the code"))
        form.setCustomSpacing(12, after: form.arrangedSubviews.last!)

        let card = FWAuthCard()
        let masked = email?.maskEmail ?? "your email"
        let info = UILabel()
        info.numberOfLines = 0
        info.adjustsFontForContentSizeCategory = true
        let text = NSMutableAttributedString(
            string: "We sent a 6-digit code to ",
            attributes: [.font: FWAuthFont.body, .foregroundColor: FireWireTheme.text])
        text.append(NSAttributedString(string: masked, attributes: [.font: FWAuthFont.bodyStrong, .foregroundColor: FireWireTheme.text]))
        text.append(NSAttributedString(string: ". It expires in 10 minutes.", attributes: [.font: FWAuthFont.body, .foregroundColor: FireWireTheme.text]))
        info.attributedText = text
        card.stack.addArrangedSubview(info)
        card.stack.addArrangedSubview(codeField)
        card.stack.addArrangedSubview(resendControl)
        card.stack.setCustomSpacing(8, after: codeField)
        card.stack.addArrangedSubview(banner)
        form.addArrangedSubview(card)
        form.setCustomSpacing(16, after: card)

        verifyButton.addTarget(self, action: #selector(verifyTap), for: .touchUpInside)
        form.addArrangedSubview(verifyButton)
        content.addArrangedSubview(form)

        resendControl.onResend = { [weak self] in self?.requestOtp() }
        codeField.textField.delegate = self
        codeField.textField.addTarget(self, action: #selector(codeChanged), for: .editingChanged)
    }

    @objc private func codeChanged() {
        codeField.setError(nil)
        banner.hide()
        let digits = (codeField.textField.text ?? "").filter(\.isNumber)
        if digits.count > codeLength { codeField.textField.text = String(digits.prefix(codeLength)) }
        if digits.count == codeLength { submitOtp() }
    }

    @objc private func verifyTap() {
        submitOtp()
    }

    @objc func backButtonTap() {
        coordinator?.popView()
    }

    @objc func resentOTPTap() {
        requestOtp()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Digits only (pasted codes may carry spaces); length is clamped in codeChanged.
        return string.isEmpty || string.filter(\.isNumber).count == string.filter { !$0.isWhitespace }.count
    }

    // Kept so existing call sites keep compiling; the screen is now built in code.
    static func instantiate() -> OtpVerificationViewController {
        return OtpVerificationViewController()
    }
}

// MARK: - API calls

extension OtpVerificationViewController {
    func submitOtp() {
        guard !isSubmitting else { return }
        guard let email = email else { return }

        let otp = (codeField.textField.text ?? "").filter(\.isNumber)
        guard otp.count == codeLength else {
            codeField.setError("Enter the 6-digit code from the email.")
            return
        }

        view.endEditing(true)
        banner.hide()
        isSubmitting = true
        showLoader()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.verifyOtp,
            payload: APIPayload.verifyOtp(email: email, otp: otp).toDictionary(),
            expect: VerifyOtpResponseModel.self
        ) { [weak self] response, _, error in
            self?.hideLoader()
            self?.isSubmitting = false

            if let errorMessage = error {
                self?.banner.show(FWAuthValidation.friendly(errorMessage), style: .error)
                return
            }

            guard let apiResponse = response as? VerifyOtpResponseModel else {
                let errorMessage = (response == nil) ? "Invalid request" : "Unexpected response format"
                self?.banner.show(errorMessage, style: .error)
                return
            }

            if apiResponse.code != "success" {
                let message = apiResponse.code == "invalid_otp"
                    ? "That code isn’t right or has expired. Check the email or request a new one."
                    : apiResponse.message
                self?.codeField.textField.text = ""
                self?.banner.show(message, style: .error)
                self?.codeField.textField.becomeFirstResponder()
                return
            }

            if let otpData = apiResponse.data {
                self?.coordinator?.navigateToResetPassword(token: otpData.resetToken)
            } else {
                self?.banner.show(.CommonError.techError, style: .error)
            }
        }
    }

    func requestOtp() {
        guard let email = email else { return }
        banner.hide()
        resendControl.showSending()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.forgotPassword,
            payload: APIPayload.forgotPassword(email: email).toDictionary(),
            expect: ForgotPasswordResponseModel.self
        ) { [weak self] response, _, error in

            self?.resendControl.start()
            if let errorMessage = error {
                self?.banner.show(FWAuthValidation.friendly(errorMessage), style: .error)
                return
            }

            guard let apiResponse = response else {
                self?.banner.show(.CommonError.techError, style: .error)
                return
            }

            if let response = apiResponse as? ForgotPasswordResponseModel {
                if response.code.lowercased() == "success" {
                    self?.codeField.textField.text = ""
                    self?.banner.show("A new code is on its way.", style: .success)
                } else {
                    self?.banner.show(response.message, style: .error)
                }
            }
        }
    }
}
