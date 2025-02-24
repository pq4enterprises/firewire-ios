//
//  DomainViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 22/02/25.
//

import UIKit

class DomainViewController: UIViewController {
    weak var coordinator: LoginCoordinator?
    @IBOutlet weak var urlLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        urlLabel.text = APIEndpoints.baseURL
    }
    
    @IBAction func devButtonTap(_ sender: UIButton) {
        APIEndpoints.baseURL = "https://dev-firewire-api.atomgroups.work/"
        urlLabel.text = APIEndpoints.baseURL
    }
    
    @IBAction func liveButtonTap(_ sender: UIButton) {
        APIEndpoints.baseURL = "https://firewire-api.atomgroups.work/"
        urlLabel.text = APIEndpoints.baseURL
    }

    @IBAction func saveButtonTap(_ sender: UIButton) {
        coordinator?.parentCoordinator?.isUserLoggedIn{isLoggedIn in
            if isLoggedIn {
                self.coordinator?.navigateToHome()
            } else {
                self.coordinator?.parentCoordinator?.navigateToLogin()
            }
        }
    }
    
    // A convenience method to instantiate from the storyboard
    static func instantiate() -> DomainViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "DomainViewController") as! DomainViewController
        return viewController
    }

}
