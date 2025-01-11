//
//  IncidentShareViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import UIKit

class IncidentShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func instantiate() -> IncidentShareViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "IncidentShareViewController") as! IncidentShareViewController
        return viewController
    }
}
