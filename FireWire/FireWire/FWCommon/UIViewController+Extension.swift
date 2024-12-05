//
//  UIViewController+Extension.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 21/11/24.
//

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Show Activity Indicator
    
    func showLoader(with style: UIActivityIndicatorView.Style = .large) {
        let activityIndicator = UIActivityIndicatorView(style: style)
        activityIndicator.tag = 999 // Tag to identify the activity indicator later
        activityIndicator.center = view.center
        activityIndicator.startAnimating()

        // Add the activity indicator to the view
        view.addSubview(activityIndicator)
        view.isUserInteractionEnabled = false // Optionally disable interaction during loading
    }

    // MARK: - Hide Activity Indicator

    func hideLoader() {
        if let activityIndicator = view.viewWithTag(999) as? UIActivityIndicatorView {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
            view.isUserInteractionEnabled = true // Re-enable interaction after loading
        }
    }
}
