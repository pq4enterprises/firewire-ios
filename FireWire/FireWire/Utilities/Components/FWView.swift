//
//  FWView.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

public class FWView: UIImageView {
    public override func layoutSubviews() {
        super.layoutSubviews()
        setCornerRadiusAndShadow()
    }

    func setCornerRadiusAndShadow(){
        self.layer.shadowColor = FWColor.red.cgColor
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowOpacity = 0.2
        self.layer.shadowRadius = 5.0
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = false
    }
}
