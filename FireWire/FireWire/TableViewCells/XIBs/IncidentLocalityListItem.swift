//
//  IncidentLocalityListItem.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 09/01/25.
//

import UIKit

class IncidentLocalityListItem: UITableViewCell {
    static let identifier = "IncidentLocalityListItem"

    static func nib() -> UINib {
        return UINib(nibName: "IncidentLocalityListItem", bundle: nil)
    }

    var localityData: LocalityResponseData?
    var indexPath: IndexPath?
    var selectedLocalities: [String] = []
    var selectedSubLocalities: [String] = []
    var onCheckboxToggled: ((IndexPath) -> Void)?

    @IBOutlet weak var subLocalityLabel: UILabel!
    @IBOutlet weak var selectSubLocalityButton: UIButton!

    @IBAction func checkButton(_ sender: UIButton) {
        guard let indexPath = indexPath else { return }
        onCheckboxToggled?(indexPath)
    }

    func setupView(_ model: LocalityResponseData, _ indexPath: IndexPath){
        localityData = model
        self.indexPath = indexPath

        let subLocality = model.subLocality[indexPath.row]
        subLocalityLabel.text = subLocality.name

        updateCheckboxState()
    }

    func updateCheckboxState() {
        guard let locality = localityData, let indexPath = indexPath else { return }
        let subLocality = locality.subLocality[indexPath.row]
        let image = subLocality.isChecked ? FWImage.checkBoxChecked : FWImage.checkBoxUnChecked
        selectSubLocalityButton.setImage(image, for: .normal)
    }
}
