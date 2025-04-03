//
//  GettinSaltyMenuCollectionViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 03/04/25.
//

import UIKit

class GettinSaltyMenuCollectionViewCell: MenuCollectionViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()

        // Rounded corners
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true

        // White border
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.yellow.cgColor
    }

}

class MenuCollectionViewCell: UICollectionViewCell {
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .gray // Set cell background to gray

        addSubview(iconImageView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 75),
            iconImageView.heightAnchor.constraint(equalToConstant: 75),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Rounded corners
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true

        // White border
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.white.cgColor
    }
}


class MenuCollectionReusableView: UICollectionReusableView {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupImageView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "img_fire")
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
    }
}
