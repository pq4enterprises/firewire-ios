//
//  SelectAreaListViewCell.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 27/11/24.
//

import UIKit

struct SelectedLocalities {
    var selectedLocalityIDs: [String]
    var selectedSubLocalityIDs: [String]
}

class SelectAreaListViewCell: UITableViewCell {
    static let identifier = "SelectAreaListViewCell"

    static func nib() -> UINib {
        return UINib(nibName: "SelectAreaListViewCell", bundle: nil)
    }

    var localityData: LocalityResponseData?
    var indexPath: IndexPath?
    var selectedLocalities: [String] = []
    var selectedSubLocalities: [String] = []
    var onCheckboxToggled: ((IndexPath) -> Void)?

    var selectAreaAction: ((SelectedLocalities) -> Void)? = nil

    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var selectAreaButton: UIButton!
    
    @IBAction func checkButton(_ sender: UIButton) {
        guard let indexPath = indexPath else { return }
        onCheckboxToggled?(indexPath)
    }

    func setupView(_ model: LocalityResponseData, _ indexPath: IndexPath){
        localityData = model
        self.indexPath = indexPath

        if indexPath.section == 1 {
            areaLabel.text = model.subLocality[indexPath.row].name
        }else if indexPath.section == 2, let units = model.unit {
            areaLabel.text = units[indexPath.row]?.unitName
        }

        updateCheckboxState()
    }

    func updateCheckboxState() {
        guard let locality = localityData, let indexPath = indexPath else { return }

        if indexPath.section == 1 {
            let subLocality = locality.subLocality[indexPath.row]
            let image = subLocality.isSelected ? FWImage.checkBoxChecked : FWImage.checkBoxUnChecked
            selectAreaButton.setImage(image, for: .normal)
        }else if indexPath.section == 2, let units = locality.unit {
            let unit = units[indexPath.row]
            let image = unit?.isChecked ?? false ? FWImage.checkBoxChecked : FWImage.checkBoxUnChecked
            selectAreaButton.setImage(image, for: .normal)
        }
    }
}
