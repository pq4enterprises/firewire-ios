//
//  LocalityCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import UIKit

class LocalityCell: UITableViewCell {
    static let identifier = "LocalityCell"

    @IBOutlet var localityTitle: UILabel!

    func setupView(_ locality: String) {
        localityTitle.text = locality
    }

}
