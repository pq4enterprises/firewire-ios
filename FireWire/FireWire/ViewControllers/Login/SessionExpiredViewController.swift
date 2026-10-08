//
//  SessionExpiredViewController.swift
//  FireWire
//
//  In-place recovery for a genuinely dead session: a modal that carries its own
//  email/password fields and Forgot Password, so the user can re-authenticate
//  right where they are. The full login screen is still routed underneath it as
//  a redundant fallback — a user should never be stranded by an expired session.
//
//  Restyled with the shared auth components (2026 auth redesign) so it matches
//  the sign-in card exactly.
//

import UIKit

class SessionExpiredViewController: UIViewController, LoginViewDelegate, UITextFieldDelegate {

    /// Called after a successful re-login, once the modal has dismissed.
    var onSignedIn: (() -> Void)?
    /// Called when the user taps FORGOT PASSWORD?, once the modal has dismissed.
    var onForgotPassword: (() -> Void)?
    /// Called when the server wants the email verified first, once the modal has dismissed.
    var onNeedsVerification: ((String) -> Void)?

    private var viewModel: LoginViewModel?

    private let scrollView = UIScrollView()
    private let card = FWAuthCard()
    private let emailField = FWAuthField(caption: "Email", placeholder: "you@example.com", kind: .email)
    private let passwordField = FWAuthField(caption: "Password", placeholder: "Enter your password", kind: .password)
    private let banner = FWBanner()
    private let signInButton = FWPrimaryButton(title: "Sign in")
    private var cardCenterY: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        viewModel = LoginViewModel()
        viewModel?.delegate = self

        buildCard()
        hideKeyboardWhenTappedAround()

        // The session that just died knew the user's email — start from it.
        emailField.textField.text = FWUserDefaults().userEmail

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UI construction

    private func buildCard() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        let titleLabel = FWAuthLabel.make("Session expired", font: FWAuthFont.screenTitle, alignment: .center, uppercase: true, kern: 0.9)
        let subtitleLabel = FWAuthLabel.body("Please sign in again to continue.", color: FireWireTheme.muted, alignment: .center)

        signInButton.addTarget(self, action: #selector(signInTap), for: .touchUpInside)

        let forgotButton = FWLinkButton(title: "Forgot password?")
        forgotButton.addTarget(self, action: #selector(forgotTap), for: .touchUpInside)

        card.stack.addArrangedSubview(titleLabel)
        card.stack.addArrangedSubview(subtitleLabel)
        card.stack.addArrangedSubview(emailField)
        card.stack.addArrangedSubview(passwordField)
        card.stack.addArrangedSubview(banner)
        card.stack.addArrangedSubview(signInButton)
        card.stack.addArrangedSubview(forgotButton)
        card.stack.setCustomSpacing(6, after: titleLabel)
        card.stack.setCustomSpacing(18, after: subtitleLabel)
        card.stack.setCustomSpacing(4, after: signInButton)
        card.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(card)

        cardCenterY = card.centerYAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerYAnchor, constant: -40)
        cardCenterY.priority = .defaultHigh
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            card.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -24),
            card.topAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            card.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            card.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24).withPriority(.defaultLow),
            card.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24).withPriority(.defaultLow),
            cardCenterY,
        ])

        emailField.textField.delegate = self
        emailField.textField.returnKeyType = .next
        passwordField.textField.delegate = self
        passwordField.textField.returnKeyType = .go
        emailField.textField.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
        passwordField.textField.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
    }

    // MARK: Keyboard

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardInView = view.convert(frame, from: nil)
        var inset = scrollView.contentInset
        inset.bottom = max(0, view.bounds.maxY - keyboardInView.minY)
        scrollView.contentInset = inset
        let cardBottom = card.convert(card.bounds, to: view).maxY + 16
        let overlap = max(0, cardBottom - keyboardInView.minY)
        cardCenterY.constant = -40 - overlap
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide() {
        var inset = scrollView.contentInset
        inset.bottom = 0
        scrollView.contentInset = inset
        cardCenterY.constant = -40
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    // MARK: Actions

    @objc private func editingChanged(_ textField: UITextField) {
        if textField === emailField.textField { emailField.setError(nil) }
        if textField === passwordField.textField { passwordField.setError(nil) }
        banner.hide()
    }

    @objc private func signInTap() {
        view.endEditing(true)
        banner.hide()

        let email = emailField.text
        let password = passwordField.textField.text ?? ""
        let emailError = FWAuthValidation.emailError(email)
        let passwordError = FWAuthValidation.passwordError(password)
        emailField.setError(emailError)
        passwordField.setError(passwordError)
        guard emailError == nil, passwordError == nil else { return }

        showLoader()
        viewModel?.performUserLogin(LoginRequestModel(email: email, password: password))
    }

    @objc private func forgotTap() {
        dismiss(animated: true) {
            self.onForgotPassword?()
        }
    }

    // MARK: LoginViewDelegate

    func loginSuccess(_ type: LoginType) {
        hideLoader()
        dismiss(animated: true) {
            self.onSignedIn?()
        }
    }

    func loginFailed(errorMessage: String) {
        hideLoader()
        banner.show(FWAuthValidation.friendly(errorMessage), style: .error)
    }

    func loginRequiresEmailVerification(email: String) {
        hideLoader()
        dismiss(animated: true) {
            self.onNeedsVerification?(email)
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField.textField {
            passwordField.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            signInTap()
        }
        return true
    }
}

private extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
