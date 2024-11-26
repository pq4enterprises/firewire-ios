//
//  FWRoundedImageView.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 24/11/24.
//

import UIKit

public class FWRoundedImageView: UIImageView {
    public override func layoutSubviews() {
        super.layoutSubviews()
        setCornerRadius()
    }

    func setCornerRadius(){
        self.layer.cornerRadius = frame.size.width / 2
        self.layer.masksToBounds = false
        self.clipsToBounds = true
    }
}
