//
//  ForceUpdateViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 01/07/25.
//

import UIKit

class ForceUpdateViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> ForceUpdateViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ForceUpdateViewController") as! ForceUpdateViewController
        return viewController
    }

    @IBAction func updateNowClicked(_ sender: UIButton) {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id980572369") {
            UIApplication.shared.open(url)
        }
    }
}
