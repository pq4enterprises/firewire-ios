//
//  LoginViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import UIKit

class LoginViewController: UIViewController {

    weak var coordinator: LoginCoordinator?

    @IBOutlet weak var registerLabel: UILabel!
    @IBOutlet weak var termsAndConditionsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
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

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> LoginViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        return viewController
    }
}
