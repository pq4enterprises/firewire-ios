//
//  MenuViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

class MenuViewController: UIViewController {

    var coordinator: HomeCoordinator?

    @IBOutlet weak var profileImage: FWRoundedImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
    }
    
    func setupActions(){
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTap))
        profileImage.isUserInteractionEnabled = true
        profileImage.addGestureRecognizer(imageTapGesture)
    }

    /// Temporary logout
    @objc func profileImageTap() {
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.appCoordinator?.logout()
        }
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
