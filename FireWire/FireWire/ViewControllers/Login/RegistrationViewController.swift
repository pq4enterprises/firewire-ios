//
//  RegistrationViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import UIKit

class RegistrationViewController: UIViewController {
    var coordinator: LoginCoordinator?

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var signInLabel: UILabel!
    @IBOutlet var firstNameTextField: FWTextField!
    @IBOutlet var lastNameTextField: FWTextField!
    @IBOutlet var emailTextField: FWTextField!
    @IBOutlet var phoneTextField: FWTextField!
    @IBOutlet var positionTextField: FWTextField!
    @IBOutlet var passwordTextField: FWTextField!
    @IBOutlet var confirmPasswordTextField: FWTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardActions()
    }

    func setupUI() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
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

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.pop()
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
