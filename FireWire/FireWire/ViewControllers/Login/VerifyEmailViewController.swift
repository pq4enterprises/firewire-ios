//
//  VerifyEmailViewController.swift
//  FireWire
//
//  Email verification after sign-up (2026 auth redesign). The iOS counterpart
//  of Android's VerifyEmailOtpActivity: the server has already emailed a
//  6-digit code; this screen calls verify-email-otp (and resend-email-otp)
//  exactly as Android does. A successful verification returns full login data,
//  which is stored the same way LoginViewModel stores a sign-in.
//
//  Reached from: registration (always), sign-in and forgot-password when the
//  server answers "email_not_verified" (only once ENFORCE_EMAIL_VERIFICATION
//  is switched on server-side).
//

import OneSignalFramework
import UIKit

enum VerifyEmailOrigin {
    case register
    case login
    case forgotPassword
}

class VerifyEmailViewController: FWAuthScreenController, UITextFieldDelegate {
    weak var coordinator: LoginCoordinator?
    var email: String = ""
    var origin: VerifyEmailOrigin = .register

    override var analyticsScreenName: String? { "Verify Email" }

    private let codeField = FWAuthField(caption: "Verification code", placeholder: "••••••", kind: .code)
    private let resendControl = FWResendControl()
    private let banner = FWBanner()
    private let verifyButton = FWPrimaryButton(title: "Verify")
    private let codeLength = 6
    private var isSubmitting = false
    private let viewModel = VerifyEmailViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        viewModel.delegate = self
        resendControl.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        codeField.textField.becomeFirstResponder()
    }

    private func buildLayout() {
        installTopBar(title: "Verify email") { [weak self] in self?.coordinator?.popView() }

        let form = UIStackView()
        form.axis = .vertical
        form.isLayoutMarginsRelativeArrangement = true
        form.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 20, trailing: 12)

        // Icon + explanation
        let iconCircle = UIView()
        iconCircle.backgroundColor = FireWireTheme.redTint
        iconCircle.layer.cornerRadius = 28
        iconCircle.widthAnchor.constraint(equalToConstant: 56).isActive = true
        iconCircle.heightAnchor.constraint(equalToConstant: 56).isActive = true
        let icon = UIImageView(image: UIImage(systemName: "envelope", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)))
        icon.tintColor = FireWireTheme.red
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
        ])
        let explain = FWAuthLabel.body("Check your inbox. We emailed a 6-digit code to confirm this address.", alignment: .center)
        let header = UIStackView(arrangedSubviews: [iconCircle, explain])
        header.axis = .vertical
        header.alignment = .center
        header.spacing = 10
        header.isLayoutMarginsRelativeArrangement = true
        header.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 16, trailing: 12)
        form.addArrangedSubview(header)

        let card = FWAuthCard()
        let emailField = FWAuthField(caption: "Email", kind: .readOnly)
        emailField.textField.text = email
        card.stack.addArrangedSubview(emailField)
        card.stack.addArrangedSubview(codeField)
        card.stack.addArrangedSubview(resendControl)
        card.stack.setCustomSpacing(8, after: codeField)
        card.stack.addArrangedSubview(banner)
        form.addArrangedSubview(card)
        form.setCustomSpacing(16, after: card)

        verifyButton.addTarget(self, action: #selector(verifyTap), for: .touchUpInside)
        form.addArrangedSubview(verifyButton)
        form.setCustomSpacing(12, after: verifyButton)

        let hint = FWAuthLabel.body("Codes expire after 10 minutes. Check spam if it hasn’t arrived.", color: FireWireTheme.muted, alignment: .center)
        hint.font = FWAuthFont.caption
        form.addArrangedSubview(hint)
        content.addArrangedSubview(form)

        resendControl.onResend = { [weak self] in self?.resendCode() }
        codeField.textField.delegate = self
        codeField.textField.addTarget(self, action: #selector(codeChanged), for: .editingChanged)
    }

    @objc private func codeChanged() {
        codeField.setError(nil)
        banner.hide()
        let digits = (codeField.textField.text ?? "").filter(\.isNumber)
        if digits.count > codeLength { codeField.textField.text = String(digits.prefix(codeLength)) }
        if digits.count == codeLength { verifyTap() }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.isEmpty || string.filter(\.isNumber).count == string.filter { !$0.isWhitespace }.count
    }

    @objc private func verifyTap() {
        guard !isSubmitting else { return }
        let otp = (codeField.textField.text ?? "").filter(\.isNumber)
        guard otp.count == codeLength else {
            codeField.setError("Enter the 6-digit code from the email.")
            return
        }
        view.endEditing(true)
        banner.hide()
        isSubmitting = true
        showLoader()
        viewModel.verifyEmailOtp(email: email, otp: otp)
    }

    private func resendCode() {
        banner.hide()
        resendControl.showSending()
        viewModel.resendEmailOtp(email: email)
    }
}

extension VerifyEmailViewController: VerifyEmailViewModelDelegate {
    func verificationSucceeded(_ loginData: LoginDataModel) {
        hideLoader()
        isSubmitting = false
        switch origin {
        case .forgotPassword:
            // Verification only unblocks the reset; the user still wants a new password.
            coordinator?.returnToForgotPasswordAfterVerification()
        case .register, .login:
            coordinator?.navigateToSelectArea()
        }
    }

    func verificationFailed(code: String?, message: String) {
        hideLoader()
        isSubmitting = false
        if code == "invalid_otp" {
            codeField.textField.text = ""
            banner.show("That code isn’t right or has expired. Check the email or request a new one.", style: .error)
            codeField.textField.becomeFirstResponder()
        } else if code == "already_registered_login" {
            banner.show("This email is already verified. Please sign in.", style: .info)
        } else {
            banner.show(FWAuthValidation.friendly(message), style: .error)
        }
    }

    func resendSucceeded(message: String) {
        resendControl.start()
        codeField.textField.text = ""
        banner.show("A new code is on its way.", style: .success)
    }

    func resendFailed(message: String) {
        resendControl.start()
        banner.show(FWAuthValidation.friendly(message), style: .error)
    }
}

// MARK: - View model

protocol VerifyEmailViewModelDelegate: AnyObject {
    func verificationSucceeded(_ loginData: LoginDataModel)
    func verificationFailed(code: String?, message: String)
    func resendSucceeded(message: String)
    func resendFailed(message: String)
}

final class VerifyEmailViewModel {
    weak var delegate: VerifyEmailViewModelDelegate?

    /// POST api/app/auth/verify-email-otp {email, otp} — same request as Android's
    /// VerifyEmailOtpRequest; the response is the login payload (LoginApiResponse).
    func verifyEmailOtp(email: String, otp: String) {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.verifyEmailOtp,
            payload: APIPayload.verifyEmailOtp(email: email, otp: otp).toDictionary() as JSON,
            expect: LoginApiResponse.self
        ) { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.verificationFailed(code: nil, message: errorMessage)
                return
            }

            guard let apiResponse = response as? LoginApiResponse else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self?.delegate?.verificationFailed(code: nil, message: errorMessage)
                return
            }

            if apiResponse.code != "success" {
                self?.delegate?.verificationFailed(code: apiResponse.code, message: apiResponse.message)
                return
            }

            guard let loginData = apiResponse.data else {
                self?.delegate?.verificationFailed(code: nil, message: "Missing login data")
                return
            }

            // Persist the session exactly as a password sign-in does (LoginViewModel).
            if let userId = loginData.id {
                OneSignal.login(userId)
            }
            FWUserDefaults.setStringForKey(key: .userIDKey, value: loginData.id)
            let userName = "\(loginData.firstName ?? "") \(loginData.lastName ?? "")"
            FWUserDefaults.setStringForKey(key: .userNameKey, value: userName)
            FWUserDefaults.setStringForKey(key: .userEmailKey, value: loginData.email)
            FWUserDefaults.setStringForKey(key: .userTokenKey, value: loginData.token)
            FWUserDefaults.setStringForKey(key: .refreshTokenKey, value: loginData.refreshToken)
            FWUserDefaults.setStringForKey(key: .userRoleKey, value: loginData.role)

            self?.delegate?.verificationSucceeded(loginData)
        }
    }

    /// POST api/app/auth/resend-email-otp {email} — same as Android's ResendOtpRequest.
    func resendEmailOtp(email: String) {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.resendEmailOtp,
            payload: APIPayload.resendEmailOtp(email: email).toDictionary() as JSON,
            expect: LoginApiResponse.self
        ) { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.resendFailed(message: errorMessage)
                return
            }

            guard let apiResponse = response as? LoginApiResponse else {
                self?.delegate?.resendFailed(message: (response == nil) ? "Invalid response" : "Unexpected response format")
                return
            }

            if apiResponse.code == "success" {
                self?.delegate?.resendSucceeded(message: apiResponse.message)
            } else {
                self?.delegate?.resendFailed(message: apiResponse.message)
            }
        }
    }
}
