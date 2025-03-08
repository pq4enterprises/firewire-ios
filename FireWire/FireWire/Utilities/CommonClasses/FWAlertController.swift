//
//  FWAlertController.swift
//  FireWire
//

import UIKit

public extension UIViewController {
    func showAlert(title: String, message: String, actions: [UIAlertAction], cancel: Bool = false) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for action in actions {
            alertController.addAction(action)
        }
        if cancel {
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
            alertController.addAction(cancelAction)
        }
        self.present(alertController, animated: true, completion: nil)
    }
}
