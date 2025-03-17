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

    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)

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

        signInLabel.colorString(
            text: .Register.signInText,
            coloredText: .Register.signIn
        )
        let signInTapGesture = UITapGestureRecognizer(target: self, action: #selector(signInTap))
        signInLabel.isUserInteractionEnabled = true
        signInLabel.addGestureRecognizer(signInTapGesture)
    }

    func togglePasswordVisibility(_ textField: UITextField) {
        textField.isSecureTextEntry.toggle()
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

        // Calculate the inset of the scroll view
        let keyboardHeight = keyboardFrame.height

        // Set the content inset for the scroll view
        var contentInset = scrollView.contentInset
        contentInset.bottom = keyboardHeight
        scrollView.contentInset = contentInset

        // Adjust the scroll indicator inset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        // Reset the content inset when the keyboard hides
        var contentInset = scrollView.contentInset
        contentInset.bottom = 0
        scrollView.contentInset = contentInset

        // Reset the scroll indicator inset
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

extension RegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length

        if textField == phoneTextField {
            // Allow only numbers (0-9) and prevent special characters
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)

            return allowedCharacters.isSuperset(of: characterSet) && newLength <= 15
        } else if textField == passwordTextField || textField == confirmPasswordTextField {
            if string == " " {
                return false // Reject space
            }
            return newLength <= 15
        }else if textField == firstNameTextField || textField == lastNameTextField {
            return newLength <= 30
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
        // coordinator?.backToParentCoordinator()
        // parentCoordinator?.navigateToHome()
    }

    func loginFailed(errorMessage: String) {
        hideLoader()
        showAlert(title: "", message: errorMessage, actions: [UIAlertAction(title: "Ok", style: .cancel)])
    }
}
