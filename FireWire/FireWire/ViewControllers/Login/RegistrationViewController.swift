//
//  RegistrationViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//  Rebuilt on FireWireTheme (2026 auth redesign). After a successful
//  registration the user now verifies their email with the code the server
//  sent, exactly as Android does, instead of being logged straight in.
//

import UIKit

protocol RegistrationViewModelDelegate: AnyObject {
    /// The account was created (or an unverified one re-registered) and a code was emailed.
    func registrationSuccess(email: String)
    func registrationFail(errorMessage: String)
}

class RegistrationViewController: FWAuthScreenController {
    weak var parentCoordinator: AppCoordinator?
    var coordinator: LoginCoordinator?
    var viewModel: RegistrationViewModel?

    override var analyticsScreenName: String? { "Register User" }

    private let firstNameField = FWAuthField(caption: "First name", placeholder: "First", kind: .givenName)
    private let lastNameField = FWAuthField(caption: "Last name", placeholder: "Last", kind: .familyName)
    private let emailField = FWAuthField(caption: "Email", placeholder: "you@example.com", kind: .newEmail)
    private let phoneField = FWAuthField(caption: "Phone", placeholder: "10 digits", kind: .phone)
    private let titleField = FWAuthField(caption: "Title / position", placeholder: "e.g. Lieutenant", kind: .jobTitle)
    private let passwordField = FWAuthField(caption: "Password", placeholder: "At least 8 characters", kind: .newPassword)
    private let confirmPasswordField = FWAuthField(caption: "Confirm password", placeholder: "Re-enter password", kind: .newPassword)
    private let formBanner = FWBanner()
    private let signUpButton = FWPrimaryButton(title: "Sign up")
    private let nameRow = UIStackView()
    private let phoneRow = UIStackView()
    private var orderedFields: [FWAuthField] { [firstNameField, lastNameField, emailField, phoneField, titleField, passwordField, confirmPasswordField] }

    func setViewModel(viewModel: RegistrationViewModel) {}

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        viewModel = RegistrationViewModel(delegate: self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateRowAxes()
        }
    }

    // MARK: Layout

    private func buildLayout() {
        installTopBar(title: "Sign up") { [weak self] in self?.coordinator?.popView() }

        let form = UIStackView()
        form.axis = .vertical
        form.isLayoutMarginsRelativeArrangement = true
        form.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 16, trailing: 12)

        let intro = FWAuthLabel.body("Create your account. All fields are required.", color: FireWireTheme.muted)
        form.addArrangedSubview(intro)
        form.setCustomSpacing(12, after: intro)

        let card = FWAuthCard()
        for row in [nameRow, phoneRow] {
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.alignment = .top
            row.spacing = 12
        }
        nameRow.addArrangedSubview(firstNameField)
        nameRow.addArrangedSubview(lastNameField)
        phoneRow.addArrangedSubview(phoneField)
        phoneRow.addArrangedSubview(titleField)
        card.stack.addArrangedSubview(nameRow)
        card.stack.addArrangedSubview(emailField)
        card.stack.addArrangedSubview(phoneRow)
        card.stack.addArrangedSubview(passwordField)
        card.stack.addArrangedSubview(confirmPasswordField)
        card.stack.addArrangedSubview(formBanner)
        form.addArrangedSubview(card)
        form.setCustomSpacing(10, after: card)

        let hint = FWAuthLabel.body("We’ll email you a 6-digit code to verify this address.", color: FireWireTheme.muted, alignment: .center)
        hint.font = FWAuthFont.caption
        form.addArrangedSubview(hint)
        content.addArrangedSubview(form)

        // Pinned footer: SIGN UP + "Already have an account? SIGN IN"
        signUpButton.addTarget(self, action: #selector(signUpButtonTap), for: .touchUpInside)
        let signInLabel = UILabel()
        signInLabel.numberOfLines = 0
        signInLabel.adjustsFontForContentSizeCategory = true
        signInLabel.setLinkSentence("Already have an account?", link: "Sign in")
        signInLabel.isUserInteractionEnabled = true
        signInLabel.isAccessibilityElement = true
        signInLabel.accessibilityTraits = .button
        signInLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(signInTap)))
        signInLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        let footerStack = UIStackView(arrangedSubviews: [signUpButton, signInLabel])
        footerStack.axis = .vertical
        footerStack.spacing = 2
        installFooter(footerStack)

        let fields = orderedFields
        for (index, field) in fields.enumerated() {
            field.textField.delegate = self
            field.textField.returnKeyType = index == fields.count - 1 ? .done : .next
            field.textField.tag = index
            field.textField.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
        }
        updateRowAxes()
    }

    /// Side-by-side pairs stack vertically at accessibility text sizes.
    private func updateRowAxes() {
        let stacked = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        nameRow.axis = stacked ? .vertical : .horizontal
        phoneRow.axis = stacked ? .vertical : .horizontal
        nameRow.spacing = stacked ? 14 : 12
        phoneRow.spacing = stacked ? 14 : 12
    }

    // MARK: Actions

    @objc private func editingChanged(_ textField: UITextField) {
        orderedFields.first { $0.textField === textField }?.setError(nil)
        formBanner.hide()
    }

    @objc func signInTap() {
        coordinator?.popView()
    }

    @objc func backButtonTap() {
        coordinator?.popView()
    }

    @objc func signUpButtonTap() {
        view.endEditing(true)
        formBanner.hide()

        let requestModel = RegisterRequestModel(
            firstName: firstNameField.text,
            lastName: lastNameField.text,
            email: emailField.text,
            mobile: phoneField.text,
            password: passwordField.textField.text ?? "",
            confirmPassword: confirmPasswordField.textField.text ?? "",
            title: titleField.text
        )

        guard validateInline(requestModel) else { return }

        showLoader()
        viewModel?.registerNewUser(requestModel)
    }

    /// Same rules as RegistrationViewModel.validate, surfaced per field instead of as one alert.
    private func validateInline(_ model: RegisterRequestModel) -> Bool {
        var firstInvalid: FWAuthField?
        func flag(_ field: FWAuthField, _ message: String?) {
            field.setError(message)
            if message != nil, firstInvalid == nil { firstInvalid = field }
        }

        flag(firstNameField, model.firstName.isEmpty ? "Enter your first name." : nil)
        flag(lastNameField, model.lastName.isEmpty ? "Enter your last name." : nil)
        flag(emailField, FWAuthValidation.emailError(model.email))
        let digits = model.mobile.filter(\.isNumber)
        flag(phoneField, model.mobile.isEmpty ? "Enter your phone number." : (digits.count < 10 ? "Enter a valid 10-digit phone number." : nil))
        flag(titleField, model.title.isEmpty ? "Enter your title or position." : nil)
        flag(passwordField, FWAuthValidation.passwordError(model.password))
        if model.confirmPassword.isEmpty {
            flag(confirmPasswordField, "Confirm your password.")
        } else if model.password != model.confirmPassword {
            flag(confirmPasswordField, "Passwords don’t match.")
        } else {
            flag(confirmPasswordField, nil)
        }

        if let firstInvalid {
            let rect = firstInvalid.convert(firstInvalid.bounds, to: scrollView).insetBy(dx: 0, dy: -24)
            scrollView.scrollRectToVisible(rect, animated: true)
            return false
        }
        return true
    }

    // Kept so existing call sites keep compiling; the screen is now built in code.
    static func instantiate() -> RegistrationViewController {
        return RegistrationViewController()
    }
}

extension RegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let fields = orderedFields
        let next = textField.tag + 1
        if next < fields.count {
            fields[next].textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            signUpButtonTap()
        }
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField === phoneField.textField {
            // Digits only, matching Android's android:digits="0123456789"
            return string.isEmpty || string.allSatisfy(\.isNumber)
        }
        return true
    }
}

extension RegistrationViewController: RegistrationViewModelDelegate {
    func registrationSuccess(email: String) {
        hideLoader()
        coordinator?.navigateToVerifyEmail(email: email, origin: .register)
    }

    func registrationFail(errorMessage: String) {
        hideLoader()
        formBanner.show(FWAuthValidation.friendly(errorMessage), style: .error)
        view.layoutIfNeeded()
        let rect = formBanner.convert(formBanner.bounds, to: scrollView).insetBy(dx: 0, dy: -40)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}
