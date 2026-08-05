//
//  UIImageView+Extension.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/12/24.
//

import UIKit

extension UIImageView {
    func loadImage(from url: URL, onSuccess: (() -> Void)? = nil) {
        // Create a data task to download the image
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let data = data, let image = UIImage(data: data) {
                // Update the UIImageView on the main thread
                DispatchQueue.main.async {
                    self?.image = image
                    onSuccess?()
                }
            } else if let error = error {
                print("Failed to load image: \(error.localizedDescription)")
            }
        }.resume()
    }
}

