//
//  UIViewController+Extension.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 21/11/24.
//

import UIKit
import MaterialShowcase

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
        if view.viewWithTag(998) != nil { return }

        let dimView = UIView(frame: view.bounds)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimView.tag = 998 // Use different tag for dim background
        dimView.isUserInteractionEnabled = true

        let activityIndicator = UIActivityIndicatorView(style: style)
        activityIndicator.tag = 999 // Tag to identify the activity indicator later
        activityIndicator.center = dimView.center
        activityIndicator.startAnimating()
        activityIndicator.color = FWColor.red

        dimView.addSubview(activityIndicator)
        view.addSubview(dimView)
    }

    // MARK: - Hide Activity Indicator

    func hideLoader() {
        view.viewWithTag(998)?.removeFromSuperview()
    }


    func createMaterialShowcase(
        primaryText: String,
        secondaryText: String,
        targetView: UIView
    ) -> MaterialShowcase {
        let showcase = MaterialShowcase()
        showcase.setTargetView(view: targetView)
        showcase.primaryText = primaryText
        showcase.secondaryText = secondaryText
        showcase.backgroundViewType = .circle
        showcase.backgroundPromptColor = FWColor.red
        showcase.targetTintColor = .clear
        showcase.targetHolderColor = .clear
        showcase.backgroundRadius = 250
        return showcase
    }
}
