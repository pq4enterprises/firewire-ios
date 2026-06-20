//
//  RegistrationViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import UIKit

protocol RegistrationViewModelDelegate {
    func registrationFail(errorMessage: String)
    func loginSuccess()
    func loginFailed(errorMessage: String)
}

class RegistrationViewController: UIViewController {
    weak var parentCoordinator: AppCoordinator?
    var coordinator: LoginCoordinator?
    var viewModel: RegistrationViewModel?

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var signInLabel: UILabel!
    @IBOutlet var firstNameTextField: FWTextField!
    @IBOutlet var lastNameTextField: FWTextField!
    @IBOutlet var emailTextField: FWTextField!
    @IBOutlet var phoneTextField: FWTextField!
    @IBOutlet var positionTextField: FWTextField!
    @IBOutlet var passwordTextField: FWTextField!
    @IBOutlet var confirmPasswordTextField: FWTextField!

    func setViewModel(viewModel: RegistrationViewModel) {}

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardActions()

        viewModel = RegistrationViewModel(delegate: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true

        // Prevent iOS AutoFill from taking over secure fields (can hide rightView and interrupt editing in Simulator).
        passwordTextField.textContentType = .oneTimeCode
        confirmPasswordTextField.textContentType = .oneTimeCode
        passwordTextField.autocorrectionType = .no
        confirmPasswordTextField.autocorrectionType = .no

        passwordTextField.addRightIcon(FWImage.hidePasswordIcon!) { [weak self] in
            guard let self else { return }
            self.togglePasswordVisibility(self.passwordTextField)
        }

        confirmPasswordTextField.addRightIcon(FWImage.hidePasswordIcon!) { [weak self] in
            guard let self else { return }
            self.togglePasswordVisibility(self.confirmPasswordTextField)
        }

        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        phoneTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        emailTextField.delegate = self
        positionTextField.delegate = self

        signInLabel.colorString(
            text: .Register.signInText,
            coloredText: .Register.signIn
        )
        let signInTapGesture = UITapGestureRecognizer(target: self, action: #selector(signInTap))
        signInLabel.isUserInteractionEnabled = true
        signInLabel.addGestureRecognizer(signInTapGesture)
    }

    func togglePasswordVisibility(_ textField: UITextField) {
        let wasFirstResponder = textField.isFirstResponder
        let existingText = textField.text

        textField.isSecureTextEntry.toggle()

        // Re-apply text to prevent secure-entry cursor glitches while editing.
        textField.text = nil
        textField.text = existingText

        if wasFirstResponder {
            textField.becomeFirstResponder()
            let endPosition = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
        }

        let icon = textField.isSecureTextEntry ? FWImage.hidePasswordIcon! : FWImage.showPasswordIcon!
        if let button = textField.rightView as? UIButton {
            button.setImage(icon, for: .normal)
        }
    }

    @objc func signInTap() {
        coordinator?.popView()
    }

    func setupActions() {
        hideKeyboardWhenTappedAround()
    }

    // TODO: Handle in common place
    func setupKeyboardActions() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardFrame.height

        var contentInset = scrollView.contentInset
        contentInset.bottom = keyboardHeight
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        var contentInset = scrollView.contentInset
        contentInset.bottom = 0
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @IBAction func signUpButtonTap(_ sender: UIButton) {
        showLoader()
        let requestModel = RegisterRequestModel(
            firstName: firstNameTextField.text ?? "",
            lastName: lastNameTextField.text ?? "",
            email: emailTextField.text ?? "",
            mobile: phoneTextField.text ?? "",
            password: passwordTextField.text ?? "",
            confirmPassword: confirmPasswordTextField.text ?? "",
            title: positionTextField.text ?? ""
        )

        let validationResult = viewModel?.validate(requestModel)
        switch validationResult {
        case .success:
            viewModel?.registerNewUser(requestModel)
        case .failure(let errorMessage):
            hideLoader()
            showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
        default:
            return
        }
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> RegistrationViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "RegistrationViewController") as! RegistrationViewController
        return viewController
    }
}


