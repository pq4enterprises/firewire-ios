//
//  FWImage.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//

import UIKit

enum FWImageResources: String {
    case menuIcon = "menu_icon"
    case menuIconWhite = "menu_icon_white"
    case alertIcon = "alert_icon"
    case alertIconWhite = "alert_icon_white"
}

extension UIImage {
    static func appImage(_ name: FWImageResources) -> UIImage? {
        return UIImage(named: name.rawValue) ?? nil
    }
}

struct FWImage {
    static let menuIcon = UIImage.appImage(.menuIcon)
    static let menuIconWhite = UIImage.appImage(.menuIconWhite)
    static let alertIcon = UIImage.appImage(.alertIcon)
    static let alertIconWhite = UIImage.appImage(.alertIconWhite)
}
