//
//  CommentsImageViewItem.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 10/01/25.
//

import UIKit

class CommentsImageViewItem: UICollectionViewCell {
    static let identifier = "CommentsImageViewItem"

    static func nib() -> UINib {
        return UINib(nibName: "CommentsImageViewItem", bundle: nil)
    }

    @IBOutlet weak var imageView: UIImageView!

    func configure(with imageUrl: String) {
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true

        if let imageUrl = URL(string: imageUrl) {
            imageView.loadImage(from: imageUrl)
        }
    }

    func configure(with image: UIImage) {
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        imageView.image = image
    }
}
