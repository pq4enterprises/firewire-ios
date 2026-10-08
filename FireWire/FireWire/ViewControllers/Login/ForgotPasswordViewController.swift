//
//  ForgotPasswordViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//  Rebuilt on FireWireTheme (2026 auth redesign): step 1 of 3 of the reset flow.
//

import UIKit

class ForgotPasswordViewController: FWAuthScreenController {
    var coordinator: LoginCoordinator?

    /// Set by the coordinator when the user comes back from verifying an
    /// unverified email, so they know the reset can now go ahead.
    var pendingVerifiedNotice = false

    override var analyticsScreenName: String? { "Forgot Password" }

    private let emailField = FWAuthField(caption: "Email", placeholder: "you@example.com", kind: .email)
    private let banner = FWBanner()
    private let sendButton = FWPrimaryButton(title: "Send code")

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if pendingVerifiedNotice {
            pendingVerifiedNotice = false
            banner.show("Email verified. Tap Send code to reset your password.", style: .success)
        }
    }

    private func buildLayout() {
        installTopBar(title: "Reset password") { [weak self] in self?.coordinator?.popView() }

        let form = UIStackView()
        form.axis = .vertical
        form.isLayoutMarginsRelativeArrangement = true
        form.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 20, trailing: 12)

        form.addArrangedSubview(FWAuthStepHeader(step: 1, title: "Your email"))
        form.setCustomSpacing(12, after: form.arrangedSubviews.last!)

        let card = FWAuthCard()
        card.stack.addArrangedSubview(FWAuthLabel.body("Enter the email on your account and we’ll send you a 6-digit code."))
        card.stack.addArrangedSubview(emailField)
        card.stack.addArrangedSubview(banner)
        form.addArrangedSubview(card)
        form.setCustomSpacing(16, after: card)

        sendButton.addTarget(self, action: #selector(confirmButtonTap), for: .touchUpInside)
        form.addArrangedSubview(sendButton)
        form.setCustomSpacing(12, after: sendButton)

        let hint = FWAuthLabel.body("Unverified account? You’ll be asked to verify your email first.", color: FireWireTheme.muted, alignment: .center)
        hint.font = FWAuthFont.caption
        form.addArrangedSubview(hint)
        content.addArrangedSubview(form)

        emailField.textField.delegate = self
        emailField.textField.returnKeyType = .send
        emailField.textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }

    @objc private func editingChanged() {
        emailField.setError(nil)
        banner.hide()
    }

    @objc func backButtonTap() {
        coordinator?.popView()
    }

    @objc func confirmButtonTap() {
        view.endEditing(true)
        banner.hide()
        let email = emailField.text
        if let error = FWAuthValidation.emailError(email) {
            emailField.setError(error)
            return
        }

        showLoader()
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.forgotPassword,
            payload: APIPayload.forgotPassword(email: email).toDictionary(),
            expect: ForgotPasswordResponseModel.self
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

            if let response = apiResponse as? ForgotPasswordResponseModel {
                switch response.code.lowercased() {
                case "success":
                    self?.coordinator?.navigateToOtpVerification(email: email)
                case "email_not_verified":
                    // The server just emailed a *verification* code; verify first, then reset.
                    self?.coordinator?.navigateToVerifyEmail(email: email, origin: .forgotPassword)
                default:
                    self?.banner.show(response.message, style: .error)
                }
            }
        }
    }

    // Kept so existing call sites keep compiling; the screen is now built in code.
    static func instantiate() -> ForgotPasswordViewController {
        return ForgotPasswordViewController()
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        confirmButtonTap()
        return true
    }
}

/// "STEP 1 OF 3 · YOUR EMAIL" header shared by the three reset screens.
final class FWAuthStepHeader: UIView {
    init(step: Int, title: String) {
        super.init(frame: .zero)
        let stepLabel = FWAuthLabel.monoCaption("Step \(step) of 3", color: FireWireTheme.red, alignment: .natural)
        let dot = UIView()
        dot.backgroundColor = FireWireTheme.muted
        dot.layer.cornerRadius = 2
        dot.widthAnchor.constraint(equalToConstant: 4).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 4).isActive = true
        let titleLabel = FWAuthLabel.monoCaption(title, alignment: .natural)
        let row = UIStackView(arrangedSubviews: [stepLabel, dot, titleLabel, UIView()])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        isAccessibilityElement = true
        accessibilityLabel = "Step \(step) of 3, \(title)"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

/// Countdown + RESEND control shared by the code-entry screens (30 s, like Android).
final class FWResendControl: UIView {
    var onResend: (() -> Void)?
    private let timerLabel = FWAuthLabel.make(font: FWAuthFont.mono(11, weight: .bold, maximum: 15), color: FireWireTheme.muted)
    private let resendButton = FWLinkButton(title: "Resend code")
    private var timer: Timer?
    private var remaining = 0

    init() {
        super.init(frame: .zero)
        resendButton.addAction(UIAction { [weak self] _ in self?.onResend?() }, for: .touchUpInside)
        let row = UIStackView(arrangedSubviews: [timerLabel, UIView(), resendButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        timerLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit { timer?.invalidate() }

    func start(seconds: Int = 30) {
        timer?.invalidate()
        remaining = seconds
        resendButton.isEnabled = false
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    func showSending() {
        timer?.invalidate()
        timerLabel.text = "Sending code…"
        resendButton.isEnabled = false
    }

    private func tick() {
        if remaining <= 0 {
            timer?.invalidate()
            timerLabel.text = "Didn’t get it?"
            resendButton.isEnabled = true
        } else {
            timerLabel.text = String(format: "Resend code in 00:%02d", remaining)
            remaining -= 1
        }
    }
}
