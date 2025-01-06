//
//  LocalityCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

class NotificationLocalityCell: UITableViewCell {
    static let identifier = "NotificationLocalityCell"

    @IBOutlet var localityTitle: UILabel!

    func setupView(_ locality: String) {
        localityTitle.text = locality
    }

}
