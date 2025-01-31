//
//  RegistrationViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import UIKit

protocol RegistrationViewModelDelegate {
    func registrationSuccess()
    func registrationFail(errorMessage: String)
}

class RegistrationViewController: UIViewController {
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

        passwordTextField.addRightIcon(UIImage(named: "eye_icon")!)
        confirmPasswordTextField.addRightIcon(UIImage(named: "eye_icon")!)

        confirmPasswordTextField.delegate = self

        signInLabel.colorString(
            text: .Register.signInText,
            coloredText: .Register.signIn
        )
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

    fileprivate func showAlertMessage(_ errorMessage: String, action: (() -> Void)? = nil) {
        showAlert(
            title: "",
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Okay"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }
    
    @IBAction func signUpButtonTap(_ sender: UIButton) {
        showLoader()
        let requestModel = RegisterRequestModel(
            firstName: firstNameTextField.text ?? "",
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
            showAlertMessage(errorMessage)
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
}

extension RegistrationViewController: RegistrationViewModelDelegate {
    func registrationSuccess() {
        hideLoader()
        showAlertMessage("New user registered"){
            self.coordinator?.popView()
        }
    }

    func registrationFail(errorMessage: String) {
        hideLoader()
        showAlertMessage(errorMessage)
    }
}
