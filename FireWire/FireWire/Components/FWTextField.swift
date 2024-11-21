//
//  FWTextField.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 21/11/24.
//

import UIKit

public class FWTextField: UITextField {
    public override func layoutSubviews() {
        super.layoutSubviews()
        setRoundedBorderAndColor()
    }

    func setRoundedBorderAndColor(){
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 5.0
        self.layer.masksToBounds = true
        self.layer.borderColor = FWColor.textFieldGrey.cgColor
    }
}
