//
//  SelectAreaListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//

import UIKit

class SelectAreaListViewCell: UITableViewCell {
    static let identifier = "SelectAreaListViewCell"

    static func nib() -> UINib {
        return UINib(nibName: "SelectAreaListViewCell", bundle: nil)
    }

    var selectAreaAction: (() -> Void)? = nil

    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var selectAreaButton: UIButton!
    
    @IBAction func checkButton(_ sender: UIButton) {
        selectAreaAction?()
    }

}
