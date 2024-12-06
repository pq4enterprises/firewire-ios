//
//  MyAccountViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 06/12/24.
//

import UIKit

class MyAccountViewController: UIViewController {
    weak var coordinator: HomeCoordinator?

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        if let name = UserDefaults.standard.string(forKey: "name"),
            let email = UserDefaults.standard.string(forKey: "email") {
            nameLabel.text = name
            emailLabel.text = email
        }
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }
    
    // A convenience method to instantiate from the storyboard
    static func instantiate() -> MyAccountViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MyAccountViewController") as! MyAccountViewController
        return viewController
    }

}
