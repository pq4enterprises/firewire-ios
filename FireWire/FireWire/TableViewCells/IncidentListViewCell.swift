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
    @IBOutlet weak var incidentLocation: UILabel!
    @IBOutlet weak var incidentDateTime: UILabel!
    @IBOutlet weak var incidentStarred: UILabel!
    @IBOutlet weak var incidentComments: UILabel!
    
    static func nib() -> UINib {
        return UINib(nibName: "IncidentListViewCell", bundle: nil)
    }

    func setupView(_ model: IncidentDataModel){
        incidentTitle.text = model.field1Value
        incidentDesc.text = model.description
        incidentLocation.text = model.address

        if let formattedDate = FWDateFormatter().formatDateString(model.createdAt){
            incidentDateTime.text = formattedDate
        }
    }

}
