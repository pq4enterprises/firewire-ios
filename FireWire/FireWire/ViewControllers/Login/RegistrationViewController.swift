//
//  RegistrationViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import UIKit

class RegistrationViewController: UIViewController {

    var coordinator: LoginCoordinator?

    @IBOutlet weak var signInLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI(){
        self.signInLabel.colorString(
            text: .Register.signInText,
            coloredText: .Register.signIn
        )
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> RegistrationViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "RegistrationViewController") as! RegistrationViewController
        return viewController
    }
}
