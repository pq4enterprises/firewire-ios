//
//  FWSegmentControl.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

class FWSegmentControl: UISegmentedControl {

    override func layoutSubviews() {
        super.layoutSubviews()
        setCustomFont()
    }

    func setCustomFont(){
        let font = FWFont.poppinsRegular14
        self.setTitleTextAttributes(
            [
                NSAttributedString.Key.font: font
            ], for: .normal)
        self.setTitleTextAttributes(
            [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: FWColor.red
            ], for: .selected)
    }
}
