//
//  MenuViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit
import FirebaseAnalytics

class MenuViewController: UIViewController {
    weak var appCoordinator: AppCoordinator?
    var coordinator: HomeCoordinator?

    @IBOutlet var profileImageView: FWRoundedImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var myAccountView: FWView!
    @IBOutlet var saltyWireView: UIView!
    @IBOutlet var submitTipView: UIView!
    @IBOutlet var podcastView: UIView!
    @IBOutlet var fireWireView: UIView!
    @IBOutlet var contactView: UIView!
    @IBOutlet var personalisationView: UIView!
    @IBOutlet weak var postButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: "ios_main_menu"
        ])
        setupUI()
        setupActions()
    }

    func setupUI() {
        if let name = FWUserDefaults().userName, let email = FWUserDefaults().userEmail {
            nameLabel.text = name
            emailLabel.text = email
        }

        if let profileImage = FWUserDefaults().userImage,
           let imageUrl = URL(string: profileImage)
        {
            profileImageView.loadImage(from: imageUrl)
        }

        myAccountView.setCornerRadiusAndShadow()

        if FWUserDefaults().isAdminUser() {
            postButton.isHidden = false
        }
    }

    func setupActions() {
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

    func unlockPremiumFeatureIfValid() -> Bool {
        if FWUserDefaults().userRole == "basic_user" {
            coordinator?.navigateToSubscriptionInfo()
            return true
        }
        return false
    }

    @objc func myAccountViewTap() {
        coordinator?.navigateToMyAccount()
    }

    @objc func saltyWireViewTap() {
        guard unlockPremiumFeatureIfValid() == false else { return }
        //coordinator?.openURL(APIEndpoints.saltyWireUrl)
        coordinator?.navigateToGettinSaltyMenu()
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
        present(feedbackView, animated: true)
    }

    @IBAction func postButtonTap(_ sender: UIButton) {
        coordinator?.navigateToPostWebView()
    }
    
    func clearUserDefaults() {
        FWUserDefaults.removeObjectForKey(key: .userIDKey)
        FWUserDefaults.removeObjectForKey(key: .userNameKey)
        FWUserDefaults.removeObjectForKey(key: .userEmailKey)
        FWUserDefaults.removeObjectForKey(key: .userTokenKey)
        FWUserDefaults.removeObjectForKey(key: .userImageKey)
        FWUserDefaults.removeObjectForKey(key: .userRoleKey)
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> MenuViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        return viewController
    }
}

// MARK: - API Calls

extension MenuViewController {
    func submitFeedback(reason: String) {
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
            }
        }
    }

    func deleteUser() {
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
                self?.showAlert(title: "", message: "Thank you for the feedback. Your account is deleted successfully!", actions: [UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self?.clearUserDefaults()
                    self?.appCoordinator?.backToParentCoordinator()
                })])
            }
        }
    }
}
