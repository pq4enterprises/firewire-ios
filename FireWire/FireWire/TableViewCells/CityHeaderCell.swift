//
//  CityHeaderCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 18/12/24.
//

import UIKit

class CityHeaderCell: UITableViewCell {

    static let identifier = "CityHeaderCell"

    static func nib() -> UINib {
        return UINib(nibName: "CityHeaderCell", bundle: nil)
    }

    @IBOutlet var titleLabel: UILabel!

    func setupView(title: String) {
        titleLabel.text = title
    }

}
