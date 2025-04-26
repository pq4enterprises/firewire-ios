//
//  IncidentListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/11/24.
//

import UIKit

class IncidentListViewCell: UITableViewCell {
    static let identifier = "IncidentListViewCell"

    @IBOutlet weak var incidentTitle: UILabel!
    @IBOutlet weak var incidentDesc: UILabel!
    @IBOutlet weak var incidentImageView: FWImageView!
    @IBOutlet weak var incidentLocation: UILabel!
    @IBOutlet weak var incidentDateTime: UILabel!
    @IBOutlet weak var incidentStarred: UILabel!
    @IBOutlet weak var incidentComments: UILabel!
    @IBOutlet var favouriteButton: UIButton!
    
    var selectedIncidentId: String?

    var favAction: (() -> Void)?
    var commentAction: (() -> Void)?
    var shareAction: (() -> Void)?

    static func nib() -> UINib {
        return UINib(nibName: "IncidentListViewCell", bundle: nil)
    }

    func setupView(_ model: IncidentDataModel){
        selectedIncidentId = model.id
        incidentTitle.text = model.field1Value
        incidentDesc.text = model.field2Value

        var address = model.field3Value
        if let subLocalityName = model.subLocality.first?.name, !subLocalityName.isEmpty {
            if !address.isEmpty {
                address.append(", ")
            }
            address.append(subLocalityName)
        }
        incidentLocation.text = address

        if let formattedDate = FWDateFormatter().formatDateString(model.createdAt){
            incidentDateTime.text = formattedDate
        }

        model.isLiked
            ? favouriteButton.setImage(FWImage.favIconSelected, for: .normal)
            : favouriteButton.setImage(FWImage.favIcon, for: .normal)

        incidentStarred.text = "\(model.likeCount) Likes"
        incidentComments.text = "\(model.commentCount) \(model.commentCount == 1 ? "Comment" : "Comments")"

        if let featureImageUrlString = model.featuredImageURL, let imageUrl = URL(string: featureImageUrlString)  {
            incidentImageView.loadImage(from: imageUrl)
            incidentImageView.isHidden = false
        }else{
            incidentImageView.isHidden = true
        }
    }

    @IBAction func favButtonTap(_ sender: UIButton) {
        favAction?()
    }

    @IBAction func commentButtonTap(_ sender: UIButton) {
        commentAction?()
    }

    @IBAction func shareButtonTap(_ sender: UIButton) {
        shareAction?()
    }

}
