//
//  FWToast.swift
//  FireWire
//
//

import UIKit

extension UIViewController {
    func showToast(message : String) {
        // The toast used to be a bare UILabel pinned to a hard-coded 200x50 with a
        // single line, so any message longer than roughly 28 characters was silently
        // truncated mid-word. It is now a padded container that wraps and sizes to its
        // content, bounded by the screen width.
        let container = UIView()
        container.backgroundColor = UIColor(red: 50/255, green: 88/255, blue: 117/255, alpha: 0.8)
        container.layer.cornerRadius = 10
        container.clipsToBounds = true
        container.alpha = 1.0
        container.translatesAutoresizingMaskIntoConstraints = false

        let toastLabel = UILabel()
        toastLabel.textColor = UIColor.white
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.numberOfLines = 0
        toastLabel.lineBreakMode = .byWordWrapping
        toastLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(toastLabel)
        self.view.addSubview(container)

        let minimumWidth = container.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)

        NSLayoutConstraint.activate([
            toastLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            toastLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            toastLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            toastLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            container.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            container.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: -24),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            minimumWidth
        ])

        UIView.animate(withDuration: 5.0, delay: 0.1, options: .curveEaseOut, animations: {
            container.alpha = 0.0
        }, completion: {(isCompleted) in
            container.removeFromSuperview()
        })
    }
}
