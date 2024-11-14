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
}

