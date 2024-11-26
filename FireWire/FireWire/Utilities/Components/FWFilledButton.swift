//
//  FWFilledButton.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/11/24.
//

import UIKit

public class FWFilledButton: UIButton {
    public override func layoutSubviews() {
        super.layoutSubviews()
        setCornerRadiusAndBackgroundColor()
    }

    func setCornerRadiusAndBackgroundColor(){
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = false
        self.layer.backgroundColor = FWColor.red.cgColor
    }
}
