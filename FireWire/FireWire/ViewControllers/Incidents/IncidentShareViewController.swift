//
//  IncidentShareViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import UIKit

class IncidentShareViewController: UIViewController {
    var appStoreUrl = "https://www.apple.com/in/app-store/"
    var shareMessage: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func whatsappButtonTap(_ sender: UIButton) {
        let messageToShare = "\(shareMessage) \n\n Checkout: \(appStoreUrl)"
        let urlWhatsApp = "whatsapp://send?text=\(messageToShare)"

        if let urlString = urlWhatsApp.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let whatsappURL = URL(string: urlString) {
                // Check if WhatsApp is installed
                if UIApplication.shared.canOpenURL(whatsappURL) {
                    // Open WhatsApp with the message
                    UIApplication.shared.open(whatsappURL, options: [:], completionHandler: nil)
                } else {
                    showAlertMessage("WhatsApp is not installed on this device. Please install WhatsApp to share content.")
                }
            }
        }
    }
    
    @IBAction func facebookButtonTap(_ sender: UIButton) {
        let messageToShare = "\(shareMessage) \n\n Checkout: \(appStoreUrl)"
        let urlFacebook = "fb://feed?text=\(messageToShare)"

        if let urlString = urlFacebook.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let facebookURL = URL(string: urlString) {
                // Check if Facebook is installed
                if UIApplication.shared.canOpenURL(facebookURL) {
                    // Open Facebook with the message
                    UIApplication.shared.open(facebookURL, options: [:], completionHandler: nil)
                } else {
                    showAlertMessage("Facebook is not installed on this device. Please install Facebook to share content.")
                }
            }
        }
    }
    
    @IBAction func instagramButtonTap(_ sender: UIButton) {
        let messageToShare = "\(shareMessage) \n\n Checkout: \(appStoreUrl)"
        let urlInstagram = "instagram://app?text=\(messageToShare)"

        if let urlString = urlInstagram.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let instagramURL = URL(string: urlString) {
                if UIApplication.shared.canOpenURL(instagramURL) {
                    UIApplication.shared.open(instagramURL, options: [:], completionHandler: nil)
                } else {
                    showAlertMessage("Instagram is not installed on this device. Please install Instagram to share content.")
                }
            }
        }
    }

    @IBAction func twitterButtonTap(_ sender: UIButton) {
        let messageToShare = "\(shareMessage) \n\n Checkout: \(appStoreUrl)"
        let urlTwitter = "twitter://post?message=\(messageToShare)"

        if let urlString = urlTwitter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let twitterURL = URL(string: urlString) {
                if UIApplication.shared.canOpenURL(twitterURL) {
                    UIApplication.shared.open(twitterURL, options: [:], completionHandler: nil)
                } else {
                    showAlertMessage("Twitter is not installed on this device. Please install Twitter to share content.")
                }
            }
        }
    }

    fileprivate func showAlertMessage(_ errorMessage: String, action: (() -> Void)? = nil) {
        showAlert(
            title: "",
            message: errorMessage,
            alertStyle: .alert, actionTitles: ["Ok"],
            actionStyles: [.default], actions: [{ _ in action?() }]
        )
    }

    static func instantiate() -> IncidentShareViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "IncidentShareViewController") as! IncidentShareViewController
        return viewController
    }
}
