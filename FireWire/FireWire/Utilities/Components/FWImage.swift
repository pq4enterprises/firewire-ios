//
//  FWImage.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//

import UIKit

enum FWImageResources: String {
    case appLogo = "app_logo"
    case menuIcon = "menu_icon"
    case menuIconWhite = "menu_icon_white"
    case alertIcon = "alert_icon"
    case alertIconWhite = "alert_icon_white"
    case checkBoxChecked = "checkbox_checked"
    case checkBoxUnChecked = "checkbox_unchecked"
    case mapMarker = "map_marker"
    case favIcon = "star_icon"
    case favIconSelected = "star_selected"
}

extension UIImage {
    static func appImage(_ name: FWImageResources) -> UIImage? {
        return UIImage(named: name.rawValue) ?? nil
    }
}

struct FWImage {
    static let appLogo = UIImage.appImage(.appLogo)
    static let menuIcon = UIImage.appImage(.menuIcon)
    static let menuIconWhite = UIImage.appImage(.menuIconWhite)
    static let alertIcon = UIImage.appImage(.alertIcon)
    static let alertIconWhite = UIImage.appImage(.alertIconWhite)
    static let checkBoxChecked = UIImage.appImage(.checkBoxChecked)
    static let checkBoxUnChecked = UIImage.appImage(.checkBoxUnChecked)
    static let mapMarker = UIImage.appImage(.mapMarker)
    static let favIcon = UIImage.appImage(.favIcon)
    static let favIconSelected = UIImage.appImage(.favIconSelected)
}
