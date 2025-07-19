//
//  FWNetworkManager.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 08/03/25.
//

import Network
import UIKit

class FWNetworkManager {
    static let shared = FWNetworkManager()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected: Bool = false
    private var alertController: UIAlertController?

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.dismissAlert()
                } else {
                    self?.showNoInternetAlert()
                }
            }
        }
        monitor.start(queue: queue)
    }

    func checkInternetConnection() -> Bool {
        return isConnected
    }

    private func showNoInternetAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }

        if alertController == nil {
            alertController = UIAlertController(
                title: "No Internet Connection",
                message: "Please check your internet connection.",
                preferredStyle: .alert
            )

            let cancelAction = UIAlertAction(title: "Ok", style: .cancel)
            alertController?.addAction(cancelAction)

            rootViewController.present(alertController!, animated: true)
        }
    }

    private func dismissAlert() {
        alertController?.dismiss(animated: true)
        alertController = nil
    }
}
