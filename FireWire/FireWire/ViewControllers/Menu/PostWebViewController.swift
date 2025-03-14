//
//  PostWebViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/03/25.
//

import UIKit
import WebKit

class PostWebViewController: UIViewController {
    var coordinator: HomeCoordinator?

    @IBOutlet var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let requestUrl = String(format: APIEndpoints.postAdminUrl, FWUserDefaults().userToken ?? "", "light")
        debugPrint("request url \(requestUrl)")

        if let url = URL(string: requestUrl) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        coordinator?.popView()
    }

    // A convenience method to instantiate from the storyboard
    static func instantiate() -> PostWebViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "PostWebViewController") as! PostWebViewController
        return viewController
    }
}
