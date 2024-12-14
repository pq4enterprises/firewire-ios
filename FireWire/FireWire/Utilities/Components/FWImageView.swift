//
//  FWImageView.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/12/24.
//

import UIKit

public class FWImageView: UIImageView {
    public override func layoutSubviews() {
        super.layoutSubviews()
        setRoundedCorners()
    }

    func setRoundedCorners(radius: CGFloat? = 5, borderWidth: CGFloat = 0, borderColor: UIColor = .clear) {
        // Apply the corner radius
        self.layer.cornerRadius = radius ?? self.frame.size.width / 2
        self.layer.masksToBounds = true

        // Apply border if needed
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
    }
}
