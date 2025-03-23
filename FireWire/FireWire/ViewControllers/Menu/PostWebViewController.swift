//
//  PostWebViewController.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/03/25.
//

import UIKit
import WebKit

class PostWebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    var coordinator: HomeCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()

        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let requestUrl = String(format: APIEndpoints.postAdminUrl, FWUserDefaults().userToken ?? "", isDarkMode ? "dark" : "light")
        debugPrint("request url \(requestUrl)")

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "closeWebView")
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.websiteDataStore = WKWebsiteDataStore.default()

        let webView = WKWebView(frame: view.frame, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/537.36 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/537.36"

        if let url = URL(string: requestUrl) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        view.addSubview(webView)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "closeWebView" {
            if let value = message.body as? String {
                if value == "close" {
                    coordinator?.popView()
                } else if value == "submit" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.coordinator?.popView()
                    }
                }
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if let url = navigationAction.request.url?.absoluteString {
            if url.contains("facebook.com") {
                if let fbURL = URL(string: url) {
                    UIApplication.shared.open(fbURL)
                }
                decisionHandler(.cancel, preferences)
                return
            }
        }

        preferences.allowsContentJavaScript = true
        decisionHandler(.allow, preferences)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request) // Load pop-up inside the same WKWebView
        }
        return nil
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
