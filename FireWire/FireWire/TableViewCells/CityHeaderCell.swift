//
//  CityHeaderCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

class CityHeaderCell: UITableViewCell {
    static let identifier = "CityHeaderCell"

    @IBOutlet var titleLabel: UILabel!

    func setupView() {
        titleLabel.text = "New York City"
    }
}
