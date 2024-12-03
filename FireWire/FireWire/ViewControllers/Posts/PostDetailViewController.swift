//
//  PostDetailViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//

import UIKit

class PostDetailViewController: UIViewController {
    var coordinator: HomeCoordinator?

    @IBOutlet var descriptionLabel: UILabel!

    private var isLabelExpanded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    func setupUI() {
        descriptionLabel.isUserInteractionEnabled = true
    }

    func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleLabel))
        descriptionLabel.addGestureRecognizer(tapGesture)
    }

    @objc func toggleLabel() {
        if isLabelExpanded {
            descriptionLabel.numberOfLines = 3
        } else {
            descriptionLabel.numberOfLines = 0
        }
        isLabelExpanded.toggle()
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
