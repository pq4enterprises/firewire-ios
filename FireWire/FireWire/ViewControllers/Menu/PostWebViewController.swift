//
//  PostWebViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/03/25.
//

import UIKit
import WebKit

class PostWebViewController: UIViewController, WKScriptMessageHandler {
    var coordinator: HomeCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()

        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let requestUrl = String(format: APIEndpoints.postAdminUrl, FWUserDefaults().userToken ?? "", isDarkMode ? "dark" : "light")
        debugPrint("request url \(requestUrl)")

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "closeWebView")

        let webView = WKWebView(frame: view.frame, configuration: config)
        if let url = URL(string: requestUrl) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        view.addSubview(webView)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "closeWebView" {
            coordinator?.popView()
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
