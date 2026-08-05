//
//  ChangePasswordViewController.swift
//  FireWire
//
//  2026 redesign (programmatic UIKit, FireWireTheme) — replaces the old
//  storyboard screen. Submit / validation logic is unchanged.
//

import UIKit

class ChangePasswordViewController: UIViewController, UITextFieldDelegate {
    var coordinator: HomeCoordinator?

    // MARK: Views

    private let headerBar = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let bottomBar = UIView()

    private let currentPasswordTextField = UITextField()
    private let newPasswordTextField = UITextField()
    private let confirmPasswordTextField = UITextField()

    private let submitButtonView = UIButton(type: .system)

    /// Card-styled views whose CGColor borders need refreshing on theme change.
    private var borderedViews: [UIView] = []

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        buildUI()
        hideKeyboardWhenTappedAround()
        setupKeyboardActions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // CGColor-based borders don't auto-update with dark mode
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            borderedViews.forEach {
                $0.layer.borderColor = FireWireTheme.hairline.cgColor
            }
        }
    }

    // MARK: UI construction

    private func buildUI() {
        view.backgroundColor = FireWireTheme.background
        buildHeaderBar()
        buildBottomBar()
        buildScrollContent()
        buildFieldsCard()
    }

    private func buildHeaderBar() {
        headerBar.backgroundColor = FireWireTheme.surface
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)

        let hairline = UIView()
        hairline.backgroundColor = FireWireTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(hairline)

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle(" BACK", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        backButton.tintColor = FireWireTheme.text
        backButton.addTarget(self, action: #selector(backButtonTap(_:)), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(backButton)

        let titleLabel = UILabel()
        titleLabel.text = "CHANGE PASSWORD"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = FireWireTheme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 52),

            hairline.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            backButton.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 10),
            backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: headerBar.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: -14),
        ])
    }

    private func buildBottomBar() {
        bottomBar.backgroundColor = FireWireTheme.surface
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        let hairline = UIView()
        hairline.backgroundColor = FireWireTheme.hairline
        hairline.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(hairline)

        submitButtonView.setTitle("UPDATE PASSWORD", for: .normal)
        submitButtonView.titleLabel?.font = .systemFont(ofSize: 17, weight: .heavy)
        submitButtonView.setTitleColor(.white, for: .normal)
        submitButtonView.backgroundColor = FireWireTheme.red
        submitButtonView.layer.cornerRadius = 14
        submitButtonView.addTarget(self, action: #selector(submitButton(_:)), for: .touchUpInside)
        submitButtonView.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(submitButtonView)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hairline.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            hairline.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            submitButtonView.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            submitButtonView.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            submitButtonView.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            submitButtonView.heightAnchor.constraint(equalToConstant: 54),
            submitButtonView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
    }

    private func buildScrollContent() {
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 18),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    private func buildFieldsCard() {
        let card = UIView()
        FireWireTheme.cardStyle(card)
        borderedViews.append(card)

        let fieldsStack = UIStackView()
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 14
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(fieldsStack)

        NSLayoutConstraint.activate([
            fieldsStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            fieldsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            fieldsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            fieldsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        fieldsStack.addArrangedSubview(
            fieldBlock(caption: "CURRENT PASSWORD", textField: currentPasswordTextField))
        fieldsStack.addArrangedSubview(
            fieldBlock(caption: "NEW PASSWORD", textField: newPasswordTextField))
        fieldsStack.addArrangedSubview(
            fieldBlock(caption: "CONFIRM NEW PASSWORD", textField: confirmPasswordTextField))

        contentStack.addArrangedSubview(card)
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
        textField.isSecureTextEntry = true
        textField.delegate = self
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 50))
        textField.leftViewMode = .always
        textField.rightView = visibilityToggleButton(for: textField)
        textField.rightViewMode = .always
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let block = UIStackView(arrangedSubviews: [captionLabel, textField])
        block.axis = .vertical
        block.spacing = 7
        return block
    }

    /// Eye button that shows/hides the field's text.
    private func visibilityToggleButton(for textField: UITextField) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(
            UIImage(systemName: "eye.slash",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)),
            for: .normal)
        button.tintColor = FireWireTheme.muted
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 50)
        button.addAction(UIAction { [weak self, weak textField] _ in
            guard let textField else { return }
            self?.togglePasswordVisibility(textField)
        }, for: .touchUpInside)
        return button
    }

    func togglePasswordVisibility(_ textField: UITextField) {
        textField.isSecureTextEntry.toggle()
        let iconName = textField.isSecureTextEntry ? "eye.slash" : "eye"

        if let button = textField.rightView as? UIButton {
            button.setImage(
                UIImage(systemName: iconName,
                        withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)),
                for: .normal)
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

    // MARK: Keyboard

    private func setupKeyboardActions() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        var contentInset = scrollView.contentInset
        contentInset.bottom = keyboardFrame.height
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        var contentInset = scrollView.contentInset
        contentInset.bottom = 0
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    // MARK: Actions

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

    // A convenience method to instantiate the redesigned (programmatic) screen
    static func instantiate() -> ChangePasswordViewController {
        return ChangePasswordViewController()
    }
}
