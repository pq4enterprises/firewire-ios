//
//  FWLoaderView.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/03/25.
//

import UIKit

class FWLoaderView {
    static let shared = FWLoaderView()

    private var loaderView: UIView?

    func showLoader(on view: UIView) {
        // Prevent multiple loaders
        if loaderView != nil { return }

        let loader = UIView(frame: view.bounds)
        loader.backgroundColor = .systemBackground

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = loader.center
        activityIndicator.startAnimating()
        activityIndicator.color = FWColor.red

        loader.addSubview(activityIndicator)
        view.addSubview(loader)

        loaderView = loader
    }

    func hideLoader() {
        loaderView?.removeFromSuperview()
        loaderView = nil
    }
}
