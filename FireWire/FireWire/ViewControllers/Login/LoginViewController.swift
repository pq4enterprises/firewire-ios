//
//  LoginViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import FBSDKLoginKit
import GoogleSignIn
import UIKit

protocol LoginViewDelegate: AnyObject {
    func loginSuccess()
    func loginFailed(errorMessage: String)
}

class LoginViewController: UIViewController {
    weak var coordinator: LoginCoordinator?
    weak var parentCoordinator: AppCoordinator?
    var viewModel: LoginViewModel?

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var registerLabel: UILabel!
    @IBOutlet weak var forgotPasswordLabel: UILabel!
    @IBOutlet var termsAndConditionsLabel: UILabel!
    @IBOutlet var emailTextField: FWTextField!
    @IBOutlet var passwordTextField: FWTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardActions()

        emailTextField.text = "vimaladevi@atomgroups.com"
        passwordTextField.text = "password"

        viewModel = LoginViewModel()
        viewModel?.delegate = self
    }

    func setupUI() {
        passwordTextField.delegate = self
        passwordTextField.addRightIcon(UIImage(named: "eye_icon")!) {
            debugPrint("button tapped")
        }

        registerLabel.colorString(
            text: .Login.registerText,
            coloredText: .Login.register
        )
        termsAndConditionsLabel.colorString(
            text: .Login.termsAndConditionsText,
            coloredText: .Login.termsAndConditions
        )
    }

    func setupActions() {
        hideKeyboardWhenTappedAround()

        let labelTapGesture = UITapGestureRecognizer(target: self, action: #selector(registerTap))
        registerLabel.isUserInteractionEnabled = true
        registerLabel.addGestureRecognizer(labelTapGesture)

        let forgotLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(forgotTap))
        forgotPasswordLabel.isUserInteractionEnabled = true
        forgotPasswordLabel.addGestureRecognizer(forgotLabelTapGesture)

        let termsTapGesture = UITapGestureRecognizer(target: self, action: #selector(termsAndConditionsTap))
        termsAndConditionsLabel.isUserInteractionEnabled = true
        termsAndConditionsLabel.addGestureRecognizer(termsTapGesture)
    }

    @objc func registerTap() {
        coordinator?.navigateToRegistration()
    }

    @objc func forgotTap() {
        coordinator?.navigateToForgotPassword()
    }

    @objc func termsAndConditionsTap() {
        coordinator?.openURL(APIEndpoints.termsAndConditionUrl)
    }

    @IBAction func signInTap(_ sender: UIButton) {
        callLoginApi()
    }

    @IBAction func googleSignInTap(_ sender: UIButton) {
        performGoogleLogin()
    }

    @IBAction func facebookSignInTap(_ sender: UIButton) {
        performFaceBookLogin()
    }

    func callLoginApi() {
        showLoader()

        guard let email = emailTextField.text, let password = passwordTextField.text, !email.isEmpty, !password.isEmpty else {
            hideLoader()
            showAlert(title: "Warning", message: "Please enter email and password", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in }])
            return
        }

        let loginRequestModel = LoginRequestModel(email: email, password: password)
        viewModel?.performUserLogin(loginRequestModel)
    }

    func performGoogleLogin() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in

            guard error == nil else { return }

            // If sign in succeeded, display the app's main content View.
            guard let signInResult = signInResult else { return }

            signInResult.user.refreshTokensIfNeeded { user, error in
                guard error == nil else { return }
                guard let user = user else { return }

                let accessToken = user.accessToken.tokenString

                let requestModel = SocialLoginRequestModel(token: accessToken, socialType: .google, role: "basic_user")
                self.viewModel?.authenticateSocialLogin(requestModel)
            }
        }
    }

    func performFaceBookLogin() {
        let loginManager = LoginManager()
        loginManager.logOut()
            let cookies = HTTPCookieStorage.shared
            let facebookCookies = cookies.cookies(for: URL(string: "https://facebook.com/")!)
            for cookie in facebookCookies! {
                cookies.deleteCookie(cookie )
            }

        loginManager.logIn(permissions: ["public_profile"], from: self) { result, error in
            if let error = error {
                // Handle login error here
                print("Error: \(error.localizedDescription)")
            } else if let result = result, !result.isCancelled {
                // Login successful, you can access the user's Facebook data here
                //self.fetchFacebookUserData()
                let requestModel = SocialLoginRequestModel(token: AccessToken.current?.tokenString ?? "", socialType: .facebook, role: "basic_user")
                //self.viewModel?.authenticateSocialLogin(requestModel)
            } else {
                // Login was canceled by the user
                print("Login was cancelled.")
            }
        }
    }

    // TODO: Remove this if facebook user data is not required
    func fetchFacebookUserData() {
        if AccessToken.current != nil {
            // You can make a Graph API request here to fetch user data
            GraphRequest(graphPath: "me", parameters: ["fields": "id, name, email"]).start { (connection, result, error) in
                if let error = error {
                    // Handle API request error here
                    print("Error: \(error.localizedDescription)")
                } else if let userData = result as? [String: Any] {
                    // Access the user data here
                    let userID = userData["id"] as? String
                    let name = userData["name"] as? String

                    // Handle the user data as needed
                    print("User ID: \(userID ?? "")")
                    print("Name: \(name ?? "")")

                    self.coordinator?.backToParentCoordinator()
                    self.parentCoordinator?.navigateToHome()
                }
            }
        } else {
            print("No active Facebook access token.")
        }
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

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> LoginViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        return viewController
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension LoginViewController: LoginViewDelegate {
    func loginSuccess() {
        hideLoader()
        coordinator?.backToParentCoordinator()
        parentCoordinator?.navigateToHome()
    }

    func loginFailed(errorMessage: String) {
        hideLoader()
        showAlert(title: "Login Failed", message: "Technical error at our side!", alertStyle: .alert, actionTitles: ["Okay"], actionStyles: [.default], actions: [{ _ in }])
    }
}
