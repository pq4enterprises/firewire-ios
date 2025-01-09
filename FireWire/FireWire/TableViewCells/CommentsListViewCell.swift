//
//  CommentsListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/12/24.
//

import UIKit

class CommentsListViewCell: UITableViewCell {

    static let identifier = "CommentsListViewCell"

    static func nib() -> UINib {
        return UINib(nibName: "CommentsListViewCell", bundle: nil)
    }

    @IBOutlet weak var userImageView: FWRoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    func setupView(_ model: CommentsData) {
        nameLabel.text = model.userID.firstName

        if model.userID.subLocality.count > 0, let locality = model.userID.subLocality[0] {
            cityLabel.text = locality.name
        }

        descriptionLabel.text = model.comment
    }

}
