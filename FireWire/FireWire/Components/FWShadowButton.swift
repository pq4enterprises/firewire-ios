//
//  FWShadowButton.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 13/11/24.
//

import UIKit

@IBDesignable
public class FWShadowButton: UIButton {
    public override func layoutSubviews() {
        super.layoutSubviews()
        setCornerRadiusAndShadow()
    }

    func setCornerRadiusAndShadow(){
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 7)
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 5.0
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = false
    }
}
