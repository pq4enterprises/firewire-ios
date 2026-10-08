//
//  LoginViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//  Rebuilt on FireWireTheme (2026 auth redesign): programmatic layout that
//  scales from iPhone SE to Pro Max, honours Dynamic Type and dark mode, and
//  surfaces every error inline instead of in an alert.
//

import AuthenticationServices
import GoogleSignIn
import UIKit

enum LoginType: Int {
    case google
    case apple
    case general
}

protocol LoginViewDelegate: AnyObject {
    func loginSuccess(_ type: LoginType)
    func loginFailed(errorMessage: String)
    /// The account exists but its email is unverified; the server has just emailed a code.
    func loginRequiresEmailVerification(email: String)
}

class LoginViewController: FWAuthScreenController {
    weak var coordinator: LoginCoordinator?
    weak var parentCoordinator: AppCoordinator?
    var viewModel: LoginViewModel?

    /// Set by AppCoordinator when it routes here because the session expired, so the
    /// user is told *why* they are suddenly looking at a login screen. Consumed once.
    static var pendingSessionExpiryNotice = false
    /// One-shot success message shown on arrival (e.g. after a password reset).
    static var pendingSuccessNotice: String?

    override var analyticsScreenName: String? { "Login Page" }

    private let hero = FWAuthHeroView()
    private let noticeBanner = FWBanner()
    private let emailField = FWAuthField(caption: "Email", placeholder: "you@example.com", kind: .email)
    private let passwordField = FWAuthField(caption: "Password", placeholder: "Enter your password", kind: .password)
    private let formBanner = FWBanner()
    private let signInButton = FWPrimaryButton(title: "Sign in")
    private let registerLabel = UILabel()
    private let termsLabel = UILabel()
    private let socialRow = UIStackView()
    private let appleHost = FWAppleButtonHost()

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        viewModel = LoginViewModel()
        viewModel?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeroSizing()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Non-blocking inline notices: the fields, Forgot Password, and social sign-in are
        // all right here, so nothing should stand between the user and typing their password.
        if LoginViewController.pendingSessionExpiryNotice {
            LoginViewController.pendingSessionExpiryNotice = false
            noticeBanner.show("Your session ended. Please sign in again.", style: .info)
        } else if let message = LoginViewController.pendingSuccessNotice {
            LoginViewController.pendingSuccessNotice = nil
            noticeBanner.show(message, style: .success)
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateHeroSizing()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in self.updateHeroSizing(for: size) })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            updateHeroSizing()
            registerLabel.setLinkSentence("Don’t have an account?", link: "Register")
            setupTermsText()
        }
    }

    // MARK: Layout

    private func buildLayout() {
        scrollView.contentInsetAdjustmentBehavior = .never
        content.addArrangedSubview(hero)

        let form = UIStackView()
        form.axis = .vertical
        form.isLayoutMarginsRelativeArrangement = true
        form.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 12, bottom: 20, trailing: 12)

        form.addArrangedSubview(noticeBanner)
        form.setCustomSpacing(14, after: noticeBanner)

        let connectLabel = FWAuthLabel.monoCaption("Connect with")
        form.addArrangedSubview(connectLabel)
        form.setCustomSpacing(10, after: connectLabel)

        let googleButton = FWGoogleButton()
        googleButton.addTarget(self, action: #selector(googleSignInTap), for: .touchUpInside)
        appleHost.onTap = { [weak self] in self?.handleAppleSignIn() }
        socialRow.axis = .horizontal
        socialRow.distribution = .fillEqually
        socialRow.spacing = 12
        socialRow.addArrangedSubview(googleButton)
        socialRow.addArrangedSubview(appleHost)
        form.addArrangedSubview(socialRow)
        form.setCustomSpacing(14, after: socialRow)

        let orLabel = FWAuthLabel.monoCaption("or")
        form.addArrangedSubview(orLabel)
        form.setCustomSpacing(12, after: orLabel)

        let card = FWAuthCard()
        card.stack.addArrangedSubview(emailField)
        card.stack.addArrangedSubview(passwordField)
        card.stack.addArrangedSubview(formBanner)
        let forgotButton = FWLinkButton(title: "Forgot?")
        forgotButton.addTarget(self, action: #selector(forgotTap), for: .touchUpInside)
        let forgotRow = UIStackView(arrangedSubviews: [UIView(), forgotButton])
        forgotRow.axis = .horizontal
        card.stack.addArrangedSubview(forgotRow)
        card.stack.setCustomSpacing(8, after: passwordField)
        card.stack.setCustomSpacing(2, after: formBanner)
        form.addArrangedSubview(card)
        form.setCustomSpacing(16, after: card)

        signInButton.addTarget(self, action: #selector(signInTap), for: .touchUpInside)
        form.addArrangedSubview(signInButton)
        form.setCustomSpacing(6, after: signInButton)

        registerLabel.numberOfLines = 0
        registerLabel.adjustsFontForContentSizeCategory = true
        registerLabel.setLinkSentence("Don’t have an account?", link: "Register")
        registerLabel.isUserInteractionEnabled = true
        registerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(registerTap)))
        registerLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        registerLabel.isAccessibilityElement = true
        registerLabel.accessibilityTraits = .button
        form.addArrangedSubview(registerLabel)
        form.setCustomSpacing(2, after: registerLabel)

        termsLabel.numberOfLines = 0
        termsLabel.adjustsFontForContentSizeCategory = true
        setupTermsText()
        termsLabel.isUserInteractionEnabled = true
        termsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(termsAndConditionsTap)))
        termsLabel.accessibilityTraits = .link
        form.addArrangedSubview(termsLabel)

        content.addArrangedSubview(form)

        emailField.textField.delegate = self
        emailField.textField.returnKeyType = .next
        passwordField.textField.delegate = self
        passwordField.textField.returnKeyType = .go
        emailField.textField.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
        passwordField.textField.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
    }

    private func setupTermsText() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineHeightMultiple = 1.15
        let text = NSMutableAttributedString(
            string: String.Login.termsAndConditionsText,
            attributes: [.font: FWAuthFont.caption, .foregroundColor: FireWireTheme.muted, .paragraphStyle: paragraph])
        let range = (String.Login.termsAndConditionsText as NSString).range(of: String.Login.termsAndConditions)
        if range.location != NSNotFound {
            text.addAttributes([.foregroundColor: FireWireTheme.red, .font: FWAuthFont.scaled(12, weight: .heavy, maximum: 18)], range: range)
        }
        termsLabel.attributedText = text
    }

    private func updateHeroSizing(for size: CGSize? = nil) {
        let height = size?.height ?? view.bounds.height
        let safeTop = view.safeAreaInsets.top
        let largeText = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        hero.setCompact(height < 700 || largeText, safeTop: safeTop, screenHeight: height)
    }

    // MARK: Actions

    @objc private func editingChanged(_ field: UITextField) {
        if field === emailField.textField { emailField.setError(nil) }
        if field === passwordField.textField { passwordField.setError(nil) }
        formBanner.hide()
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

    @objc func signInTap() {
        callLoginApi()
    }

    @objc func googleSignInTap() {
        performGoogleLogin()
    }

    @objc func handleAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    func callLoginApi() {
        view.endEditing(true)
        formBanner.hide()

        let email = emailField.text
        let password = passwordField.textField.text ?? ""
        let emailError = FWAuthValidation.emailError(email)
        let passwordError = FWAuthValidation.passwordError(password)
        emailField.setError(emailError)
        passwordField.setError(passwordError)
        guard emailError == nil, passwordError == nil else {
            scrollView.scrollRectToVisible(emailField.convert(emailField.bounds, to: scrollView), animated: true)
            return
        }

        showLoader()
        viewModel?.performUserLogin(LoginRequestModel(email: email, password: password))
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

                self.showLoader()

                let requestModel = SocialLoginRequestModel(token: accessToken, socialType: .google, role: "basic_user")
                self.viewModel?.authenticateSocialLogin(requestModel)
            }
        }
    }

    // Kept so existing call sites keep compiling; the screen is now built in code.
    static func instantiate() -> LoginViewController {
        return LoginViewController()
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField.textField {
            passwordField.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            callLoginApi()
        }
        return true
    }
}

extension LoginViewController: LoginViewDelegate {
    func loginSuccess(_ type: LoginType) {
        viewModel?.validateIfAreaSelected(forType: .area) { result in
            self.hideLoader()
            result ? self.navigateHome() : self.coordinator?.navigateToSelectArea()
        }
    }

    private func navigateHome() {
        coordinator?.backToParentCoordinator()
        parentCoordinator?.navigateToHome()
    }

    func loginFailed(errorMessage: String) {
        hideLoader()
        formBanner.show(FWAuthValidation.friendly(errorMessage), style: .error)
        scrollFormBannerIntoView()
    }

    func loginRequiresEmailVerification(email: String) {
        hideLoader()
        coordinator?.navigateToVerifyEmail(email: email, origin: .login)
    }

    private func scrollFormBannerIntoView() {
        view.layoutIfNeeded()
        let rect = formBanner.convert(formBanner.bounds, to: scrollView).insetBy(dx: 0, dy: -40)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}

// MARK: Apple login delegate

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            if let identityToken = appleIDCredential.identityToken,
               let tokenString = String(data: identityToken, encoding: .utf8)
            {
                showLoader()

                let requestModel = SocialLoginRequestModel(token: tokenString, socialType: .apple, role: "basic_user")
                viewModel?.authenticateSocialLogin(requestModel)
            } else {
                print("Failed to get identity token.")
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Authorization Error: \(error.localizedDescription)")
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
