//
//  LoginViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import UIKit

class LoginViewController: UIViewController {

    weak var coordinator: LoginCoordinator?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var registerLabel: UILabel!
    @IBOutlet weak var termsAndConditionsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardActions()
    }

    func setupUI(){
        self.registerLabel.colorString(
            text: .Login.registerText,
            coloredText: .Login.register
        )
        self.termsAndConditionsLabel.colorString(
            text: .Login.termsAndConditionsText,
            coloredText: .Login.termsAndConditions
        )
    }

    func setupActions(){
        let labelTapGesture = UITapGestureRecognizer(target: self, action: #selector(registerTap))
        registerLabel.isUserInteractionEnabled = true
        registerLabel.addGestureRecognizer(labelTapGesture)
    }

    @objc func registerTap(){
        coordinator?.navigateToRegistration()
    }

    @IBAction func signInTap(_ sender: UIButton) {
        coordinator?.navigateToHome()
    }

    //TODO: Handle in common place
    func setupKeyboardActions(){
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

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> LoginViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        return viewController
    }
}
