//
//  RegistrationViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 16/11/24.
//

import UIKit

class RegistrationViewController: UIViewController {

    var coordinator: LoginCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // A convenience method to instantiate from the storyboard
    static func instantiate() -> RegistrationViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "RegistrationViewController") as! RegistrationViewController
        return viewController
    }
}
