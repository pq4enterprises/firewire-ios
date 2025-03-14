//
//  NotificationSoundsCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/03/25.
//

import UIKit

class NotificationSoundsCell: UITableViewCell {
    static let identifier = "NotificationSoundsCell"

    static func nib() -> UINib {
        return UINib(nibName: "NotificationSoundsCell", bundle: nil)
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tickIcon: UIImageView!

    func setupView(_ text: String, selectSound: Bool = false) {
        titleLabel.text = text
        tickIcon.isHidden = !selectSound
    }

}
