//
//  MenuViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

class MenuViewController: UIViewController {

    var coordinator: HomeCoordinator?

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var myAccountView: FWView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    func setupUI() {
        if let name = UserDefaults.standard.string(forKey: "name"),
            let email = UserDefaults.standard.string(forKey: "email") {
            nameLabel.text = name
            emailLabel.text = email
        }
    }

    func setupActions(){
        let viewTapGesture = UITapGestureRecognizer(target: self, action: #selector(myAccountViewTap))
        myAccountView.isUserInteractionEnabled = true
        myAccountView.addGestureRecognizer(viewTapGesture)
    }

    @objc func myAccountViewTap() {
        coordinator?.navigateToMyAccount()
    }

    @IBAction func closeButtonTap(_ sender: UIButton) {
        coordinator?.navigateBackToHome(popViewToLeft: true)
    }
    
    // A convenience method to instantiate from the storyboard
    static func instantiate() -> MenuViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        return viewController
    }

}
