//
//  FWAlertController.swift
//  FireWire
//

import UIKit

public extension UIViewController {
    func showAlert(title: String, message: String, actions: [UIAlertAction], cancel: Bool = false) {
        // A dead session is handled app-wide by the session-expired modal (see
        // AppCoordinator.handleSessionExpired). The same event also reaches every
        // in-flight caller as an error string; letting each of them raise a generic
        // "Ok" alert is what used to strand users behind a dead end. Swallow it here.
        if message == APIError.tokenExpired.localizedDescription {
            return
        }

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
