//
//  FWFont.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

enum CustomFont: String {
    case poppins
    case teko
    case inter
}

extension UIFont {
    static func appFont(_ name: CustomFont, size: CGFloat) -> UIFont {
        return UIFont(name: "Poppins-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
}

struct FWFont {
    static let poppinsRegular14 = UIFont.appFont(.poppins, size: 14)
}
