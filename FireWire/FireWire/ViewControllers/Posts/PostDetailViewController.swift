//
//  PostDetailViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//

import UIKit

class PostDetailViewController: UIViewController {

    var coordinator: HomeCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }
    
    // A convenience method to instantiate from the storyboard
    static func instantiate() -> PostDetailViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "PostDetailViewController") as! PostDetailViewController
        return viewController
    }

}
