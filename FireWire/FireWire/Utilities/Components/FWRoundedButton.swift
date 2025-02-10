//
//  FWRoundedButton.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

public class FWRoundedButton: UIButton {
    public override func layoutSubviews() {
        super.layoutSubviews()
        setCornerRadius()
    }

    func setCornerRadius(){
        self.layer.cornerRadius = 22
        self.layer.masksToBounds = false
    }

    func setupShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = CGSize(width: 2, height: 3)
        self.layer.shadowRadius = 5
        self.layer.masksToBounds = false
    }
}

