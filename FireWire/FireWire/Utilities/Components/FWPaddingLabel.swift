//
//  FWPaddingLabel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 06/07/26.
//

import UIKit

final class FWPaddingLabel: UILabel {

    var contentInsets = UIEdgeInsets(
        top: 4,
        left: 10,
        bottom: 4,
        right: 10
    )

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func sizeToFit() {
        invalidateIntrinsicContentSize()
        super.sizeToFit()
    }
}
