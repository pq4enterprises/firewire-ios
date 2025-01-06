//
//  NotificationLocalityHeaderView.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/12/24.
//

import UIKit

class NotificationLocalityHeaderView: UITableViewHeaderFooterView {
    static let identifier = "NotificationLocalityHeaderView"

    static func nib() -> UINib {
        return UINib(nibName: "NotificationLocalityHeaderView", bundle: nil)
    }

    @IBOutlet weak var cityTitle: UILabel!
}
