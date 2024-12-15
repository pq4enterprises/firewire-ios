//
//  LocalityHeaderCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

class LocalityHeaderCell: UITableViewCell {
    static let identifier = "LocalityHeaderCell"

    @IBOutlet var titleLabel: UILabel!

    func setupView() {
        titleLabel.text = "Sublocalities"
    }
}
