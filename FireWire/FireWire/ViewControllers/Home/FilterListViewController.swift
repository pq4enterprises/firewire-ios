//
//  FilterListViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/11/24.
//

import UIKit

class FilterListViewController: UIViewController {

    var coordinator: HomeCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func doneButtonTap(_ sender: UIButton) {
        coordinator?.dismissView()
        coordinator?.navigateToMapListView()
    }
}
