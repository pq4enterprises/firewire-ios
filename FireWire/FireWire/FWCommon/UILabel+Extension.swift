//
//  Label+Extension.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/11/24.
//

import UIKit

extension UILabel {
    func colorString(text: String?, coloredText: String?, color: UIColor? = FWColor.red) {
        let attributedString = NSMutableAttributedString(string: text!)
        let range = (text! as NSString).range(of: coloredText!)
        attributedString.setAttributes(
            [NSAttributedString.Key.foregroundColor: color!],
            range: range
        )
        self.attributedText = attributedString
    }
}
