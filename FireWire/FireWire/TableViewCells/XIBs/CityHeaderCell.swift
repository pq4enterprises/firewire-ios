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

    var selectAllAction: (() -> Void)?

    @IBOutlet var titleLabel: UILabel!
    @IBAction func selectAllButtonTap(_ sender: UIButton) {
        selectAllAction?()
    }
    
    func setupView(title: String) {
        titleLabel.text = title
    }

}
