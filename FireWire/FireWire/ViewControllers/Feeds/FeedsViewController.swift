//
//  FeedsViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

class FeedsViewController: UIViewController {

    var coordinator: HomeCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func closeButtonTap(_ sender: Any) {
        coordinator?.navigateBackToHome()
    }
    
    // A convenience method to instantiate from the storyboard
    static func instantiate() -> FeedsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FeedsViewController") as! FeedsViewController
        return viewController
    }

}
