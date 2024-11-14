//
//  FWColor.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

enum CustomColor: String {
    case FWRed
}

extension UIColor {
    static func appColor(_ name: CustomColor) -> UIColor {
        return UIColor(named: name.rawValue) ?? .black
    }
}

struct FWColor {
    static let red = UIColor.appColor(CustomColor.FWRed)
}
