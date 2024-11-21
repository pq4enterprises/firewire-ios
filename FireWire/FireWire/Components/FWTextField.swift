//
//  FWTextField.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 21/11/24.
//

import UIKit

public class FWTextField: UITextField {
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.setRoundedBorderAndColor()
        self.setLeftPaddingForTextInsets()
    }

    func setRoundedBorderAndColor() {
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 5.0
        self.layer.masksToBounds = true
        self.layer.borderColor = FWColor.textFieldGrey.cgColor
    }

    func setLeftPaddingForTextInsets() {
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: self.frame.height))
        self.leftView = leftPaddingView
        self.leftViewMode = .always
    }

    func addRightIcon(_ image: UIImage, action: (() -> Void)? = nil) {
        let frame = CGRect(x: 0, y: 0, width: image.size.width + 30, height: image.size.height + 30)

        let outerView = UIView(frame: frame)
        let button = UIButton(type: .custom)
        button.frame = frame
        button.setImage(image, for: .normal)
        outerView.addSubview(button)

        if let action = action {
            button.addAction(UIAction(handler: { _ in
                action() // Executes the closure when tapped
            }), for: .touchUpInside)
        }

        self.rightViewMode = .always
        self.rightView = outerView
    }
}
