//
//  JPTextField.swift
//  CIPO
//
//  Created by prithiviraj on 3/11/24.
//

import UIKit

@IBDesignable
open class JPTextField: UITextField {
    var rightButton  = UIButton(type: .system)
    var leftButton  = UIButton(type: .custom)
    var buttonAction: (() ->())?
    let padding = UIEdgeInsets(top: 0, left: 45, bottom: 0, right: 45)
    
    private let borderWidth: CGFloat = 1.0
    private let borderColor : UIColor = UIColor(red: 231/255, green: 231/255, blue: 231/255, alpha: 1)
    
    @IBInspectable var leftImage : UIImage? {
        didSet {
            setup()
        }
    }
    
    @IBInspectable var rightImage : UIImage? {
        didSet {
            setup()
        }
    }
    
    func setup() {
        self.clipsToBounds = false
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.masksToBounds = false
        // self.layer.shadowRadius = 0.0
        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        self.layer.shadowOffset = CGSizeMake(0.8, 0.8)
        self.layer.shadowOpacity = 0.6
        self.layer.shadowRadius =  1
        setButtonImage()
    }
    
    private func setButtonImage() {
        if let imageView = leftImage {
            leftButton.setImage(imageView, for: .normal)
            leftButton.tintColor = UIColor(red: 20.0/255.0, green: 151.0/255.0, blue: 162.0/255.0, alpha: 1.0)
            leftButton.addTarget(self, action: #selector(toggleShowHide), for: .touchUpInside)
            leftButton.imageView?.contentMode = .scaleAspectFit
            leftViewMode = .always
            leftView = leftButton
        } else {
            leftViewMode = .never
        }
        
        if let imageView = rightImage {
            rightButton.setImage(imageView, for: .normal)
            rightButton.tintColor = UIColor(red: 20.0/255.0, green: 151.0/255.0, blue: 162.0/255.0, alpha: 1.0)
            rightButton.addTarget(self, action: #selector(toggleShowHide), for: .touchUpInside)
            rightButton.imageView?.contentMode = .scaleAspectFit
            rightViewMode = .always
            rightView = rightButton
        } else {
            rightViewMode = .never
        }
    }
    
    @objc
    func toggleShowHide(button: UIButton) {
        buttonAction?()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}

extension JPTextField {
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    open override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    open override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 10, y: 0, width: 30 , height: bounds.height)
    }
    
    open override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.width - 40, y: 0, width: 30 , height: bounds.height)
    }
}
