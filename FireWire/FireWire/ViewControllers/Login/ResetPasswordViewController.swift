//
//  ResetPasswordViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import UIKit

class ResetPasswordViewController: UIViewController {
    var coordinator: LoginCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    @IBAction func submitButton(_ sender: UIButton) {
        coordinator?.popToRootView()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> ResetPasswordViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ResetPasswordViewController") as! ResetPasswordViewController
        return viewController
    }

}
