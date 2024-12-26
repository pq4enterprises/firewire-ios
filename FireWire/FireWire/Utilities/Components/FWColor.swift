//
//  FWColor.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

enum CustomColor: String {
    case FWRed
    case FWTextFieldBorderGrey
    case FWPink
    case FWGrey1
}

extension UIColor {
    static func appColor(_ name: CustomColor) -> UIColor {
        return UIColor(named: name.rawValue) ?? .black
    }
}

struct FWColor {
    static let red = UIColor.appColor(CustomColor.FWRed)
    static let textFieldGrey = UIColor.appColor(CustomColor.FWTextFieldBorderGrey)
    static let pink = UIColor.appColor(CustomColor.FWPink)
    static let textFieldBackgroundGrey = UIColor.appColor(CustomColor.FWGrey1)
}
