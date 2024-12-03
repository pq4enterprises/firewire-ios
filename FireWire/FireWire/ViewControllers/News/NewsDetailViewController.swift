//
//  NewsDetailViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 03/12/24.
//

import UIKit

class NewsDetailViewController: UIViewController {
    var coordinator: HomeCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> NewsDetailViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "NewsDetailViewController") as! NewsDetailViewController
        return viewController
    }

}
