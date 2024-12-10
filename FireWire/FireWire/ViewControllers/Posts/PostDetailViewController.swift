//
//  PostDetailViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//

import UIKit

protocol PostDetailViewDelegate: AnyObject {
    func dataReceived()
}

class PostDetailViewController: UIViewController, PostDetailViewDelegate {

    @IBOutlet weak var incidentTitle: UILabel!
    @IBOutlet weak var incidentSubTitle: UILabel!
    @IBOutlet weak var incidentDesc: UILabel!
    @IBOutlet weak var incidentDateTime: UILabel!

    var coordinator: HomeCoordinator?
    var viewModel: PostDetailViewModel?

    private var isLabelExpanded = false

    func setViewModel(viewModel: PostDetailViewModel){
        self.viewModel = viewModel
        self.viewModel?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    func setupUI() {
        incidentDesc.isUserInteractionEnabled = true
    }

    func updateUI(){
        guard let incidentDetail = viewModel?.incidentDetail else {
            return
        }
        incidentTitle.text = incidentDetail.field1Value
        incidentSubTitle.text = incidentDetail.field2Value
    }

    func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleLabel))
        incidentDesc.addGestureRecognizer(tapGesture)
    }

    @objc func toggleLabel() {
        if isLabelExpanded {
            incidentDesc.numberOfLines = 3
        } else {
            incidentDesc.numberOfLines = 0
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

    func dataReceived() {
        updateUI()
    }
}
