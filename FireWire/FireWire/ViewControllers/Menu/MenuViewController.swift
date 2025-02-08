//
//  MenuViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

class MenuViewController: UIViewController {
    weak var appCoordinator: AppCoordinator?
    var coordinator: HomeCoordinator?

    @IBOutlet weak var profileImageView: FWRoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var myAccountView: FWView!
    @IBOutlet weak var saltyWireView: UIView!
    @IBOutlet weak var submitTipView: UIView!
    @IBOutlet weak var podcastView: UIView!
    @IBOutlet weak var fireWireView: UIView!
    @IBOutlet weak var contactView: UIView!
    @IBOutlet weak var personalisationView: UIView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
        setupActions()
    }

    func setupUI() {
        if let name = UserDefaults.standard.string(forKey: "name"),
            let email = UserDefaults.standard.string(forKey: "email") {
            nameLabel.text = name
            emailLabel.text = email
        }

        if let profileImage = UserDefaults.standard.string(forKey: "profile_image"),
            let imageUrl = URL(string: profileImage) {
            profileImageView.loadImage(from: imageUrl)
        }

        myAccountView.setCornerRadiusAndShadow()
    }

    func setupActions(){
        let accountViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(myAccountViewTap))
        myAccountView.isUserInteractionEnabled = true
        myAccountView.addGestureRecognizer(accountViewTapGesture)

        let saltyWireViewGesture = UITapGestureRecognizer(target: self, action: #selector(saltyWireViewTap))
        saltyWireView.isUserInteractionEnabled = true
        saltyWireView.addGestureRecognizer(saltyWireViewGesture)

        let submitTipViewGesture = UITapGestureRecognizer(target: self, action: #selector(submitTipViewTap))
        submitTipView.isUserInteractionEnabled = true
        submitTipView.addGestureRecognizer(submitTipViewGesture)

        let podcastViewGesture = UITapGestureRecognizer(target: self, action: #selector(podcastViewTap))
        podcastView.isUserInteractionEnabled = true
        podcastView.addGestureRecognizer(podcastViewGesture)

        let fireWireViewGesture = UITapGestureRecognizer(target: self, action: #selector(fireWireViewTap))
        fireWireView.isUserInteractionEnabled = true
        fireWireView.addGestureRecognizer(fireWireViewGesture)

        let contactViewGesture = UITapGestureRecognizer(target: self, action: #selector(contactViewTap))
        contactView.isUserInteractionEnabled = true
        contactView.addGestureRecognizer(contactViewGesture)

        let personalisationViewGesture = UITapGestureRecognizer(target: self, action: #selector(personalisationViewTap))
        personalisationView.isUserInteractionEnabled = true
        personalisationView.addGestureRecognizer(personalisationViewGesture)
    }

    @objc func myAccountViewTap() {
        coordinator?.navigateToMyAccount()
    }

    @objc func saltyWireViewTap() {
        coordinator?.openURL(APIEndpoints.saltyWireUrl)
    }

    @objc func submitTipViewTap() {
        coordinator?.openURL(APIEndpoints.submitTipUrl)
    }

    @objc func podcastViewTap() {
        coordinator?.openURL(APIEndpoints.chicagoPodcastUrl)
    }

    @objc func fireWireViewTap() {
        coordinator?.openURL(APIEndpoints.fireWireUrl)
    }

    @objc func contactViewTap() {
        coordinator?.openURL(APIEndpoints.contactUrl)
    }

    @objc func personalisationViewTap() {
        coordinator?.navigateToPersonalisation()
    }

    @IBAction func closeButtonTap(_ sender: UIButton) {
        coordinator?.navigateBackToHome(popViewToLeft: true)
    }
    
    @IBAction func deleleAccountTap(_ sender: UIButton) {
        let feedbackView = FeedbackViewController.instantiate()
        feedbackView.modalPresentationStyle = .overFullScreen
        feedbackView.submitFeedback = { feedback in
            self.submitFeedback(reason: feedback)
        }
        self.present(feedbackView, animated: true)
    }

    func clearUserDefaults(){
        ["user_id", "name", "email", "token", "profile_image"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
        UserDefaults.standard.synchronize()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> MenuViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        return viewController
    }
}

//MARK: - API Calls
extension MenuViewController {
    func submitFeedback(reason: String){
        showLoader()
        let postFeedbackRequestModel = APIPayload.postReasonToAccountDelete(reason: reason).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.userProfile,
            payload: postFeedbackRequestModel as JSON,
            expect: SuccessResponseModel.self,
            requestType: APIConstants.PUT
        ) { [weak self] response, _, _ in
            self?.hideLoader()
            if response is SuccessResponseModel {
                self?.deleteUser()
                self?.clearUserDefaults()
                self?.appCoordinator?.backToParentCoordinator()
            }
        }
    }

    func deleteUser(){
        showLoader()
        let deleteRequestModel = APIPayload.deleteAccount.toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.deleteAccount,
            payload: deleteRequestModel as JSON,
            expect: SuccessResponseModel.self,
            requestType: APIConstants.PUT
        ) { [weak self] response, _, _ in
            self?.hideLoader()
            if response is SuccessResponseModel {
                self?.clearUserDefaults()
                self?.appCoordinator?.backToParentCoordinator()
            }
        }
    }
}
