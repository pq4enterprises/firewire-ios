//
//  MenuViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

class MenuViewController: UIViewController {

    var coordinator: HomeCoordinator?

    @IBOutlet weak var myAccountView: FWView!
    @IBOutlet weak var profileImage: FWRoundedImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
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
