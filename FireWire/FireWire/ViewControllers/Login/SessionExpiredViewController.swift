//
//  SessionExpiredViewController.swift
//  FireWire
//
//  In-place recovery for a genuinely dead session: a modal that carries its own
//  email/password fields and Forgot Password, so the user can re-authenticate
//  right where they are. The full login screen is still routed underneath it as
//  a redundant fallback — a user should never be stranded by an expired session.
//

import UIKit

class SessionExpiredViewController: UIViewController, LoginViewDelegate, UITextFieldDelegate {

    /// Called after a successful re-login, once the modal has dismissed.
    var onSignedIn: (() -> Void)?
    /// Called when the user taps FORGOT PASSWORD?, once the modal has dismissed.
    var onForgotPassword: (() -> Void)?

    private var viewModel: LoginViewModel?

    private let card = UIView()
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let errorLabel = UILabel()
    private let signInButton = UIButton(type: .system)

    /// Card-styled views whose CGColor borders need refreshing on theme change.
    private var borderedViews: [UIView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        viewModel = LoginViewModel()
        viewModel?.delegate = self

        buildCard()
        hideKeyboardWhenTappedAround()

        // The session that just died knew the user's email — start from it.
        emailTextField.text = FWUserDefaults().userEmail
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            borderedViews.forEach {
                $0.layer.borderColor = FireWireTheme.hairline.cgColor
            }
        }
    }

    // MARK: UI construction

    private func buildCard() {
        FireWireTheme.cardStyle(card)
        borderedViews.append(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let titleLabel = UILabel()
        titleLabel.text = "SESSION EXPIRED"
        titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
        titleLabel.textColor = FireWireTheme.text
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Please sign in again to continue."
        subtitleLabel.font = FireWireTheme.bodyFont()
        subtitleLabel.textColor = FireWireTheme.muted
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        errorLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        errorLabel.textColor = FireWireTheme.red
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        signInButton.setTitle("SIGN IN", for: .normal)
        signInButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .heavy)
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.backgroundColor = FireWireTheme.red
        signInButton.layer.cornerRadius = 14
        signInButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        signInButton.addTarget(self, action: #selector(signInTap), for: .touchUpInside)

        let forgotButton = UIButton(type: .system)
        forgotButton.setTitle("FORGOT PASSWORD?", for: .normal)
        forgotButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .heavy)
        forgotButton.tintColor = FireWireTheme.red
        forgotButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        forgotButton.addTarget(self, action: #selector(forgotTap), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            fieldBlock(caption: "EMAIL", textField: emailTextField),
            fieldBlock(caption: "PASSWORD", textField: passwordTextField),
            errorLabel,
            signInButton,
            forgotButton,
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.setCustomSpacing(6, after: titleLabel)
        stack.setCustomSpacing(18, after: subtitleLabel)
        stack.setCustomSpacing(6, after: signInButton)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
        ])
    }

    private func fieldBlock(caption: String, textField: UITextField) -> UIView {
        let captionLabel = UILabel()
        captionLabel.attributedText = NSAttributedString(
            string: caption,
            attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 9.5, weight: .bold),
                .kern: 1.0,
                .foregroundColor: FireWireTheme.muted,
            ])

        textField.font = .systemFont(ofSize: 15, weight: .semibold)
        textField.textColor = FireWireTheme.text
        textField.backgroundColor = FireWireTheme.surface2
        textField.layer.cornerRadius = 12
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.delegate = self
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 50))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 50))
        textField.rightViewMode = .always
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        if textField === emailTextField {
            textField.keyboardType = .emailAddress
        } else {
            textField.isSecureTextEntry = true
        }

        let block = UIStackView(arrangedSubviews: [captionLabel, textField])
        block.axis = .vertical
        block.spacing = 7
        return block
    }

    // MARK: Actions

    @objc private func signInTap() {
        errorLabel.isHidden = true

        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty
        else {
            showError("Enter valid email and password")
            return
        }

        let validationResult = viewModel?.validate(email: email, password: password)
        switch validationResult {
        case .success:
            showLoader()
            viewModel?.performUserLogin(LoginRequestModel(email: email, password: password))
        case .failure(let errorMessage):
            showError(errorMessage)
        default:
            return
        }
    }

    @objc private func forgotTap() {
        dismiss(animated: true) {
            self.onForgotPassword?()
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
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
        showError(errorMessage)
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            signInTap()
        }
        return true
    }
}
