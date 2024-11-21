//
//  FWTextField.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 21/11/24.
//

import UIKit

public class FWTextField: UITextField {
    var textPadding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.setRoundedBorderAndColor()
    }

    func setRoundedBorderAndColor() {
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 5.0
        self.layer.masksToBounds = true
        self.layer.borderColor = FWColor.textFieldGrey.cgColor
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

    // To override the text insets
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    public override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }
}
