//
//  FWView.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

public class FWView: UIImageView {
    func setCornerRadiusAndShadow() {
        self.layer.shadowColor = FWColor.red.cgColor
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowOpacity = 0.2
        self.layer.shadowRadius = 5.0
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = false
    }

    func addRoundedBorder() {
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 2
        self.layer.borderColor = FWColor.textFieldGrey.cgColor
        self.layer.masksToBounds = true
    }

    func setCornerRadius(){
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
    }

    func setTopCornersRadius(radius: CGFloat = 10) {
        self.layer.cornerRadius = radius
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // Top-left and top-right corners
        self.layer.masksToBounds = true
    }

    func setTopShadow(){
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: -4)
        self.layer.shadowOpacity = 0.3
        self.layer.shadowRadius = 7.0

        let shadowRect = CGRect(x: 0, y: 0, width: bounds.width, height: 5)
        layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
    }
}
