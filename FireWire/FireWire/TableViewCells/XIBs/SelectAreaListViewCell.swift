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

    var selectAreaAction: ((SelectedLocalities) -> Void)? = nil

    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var selectAreaButton: UIButton!
    
    @IBAction func checkButton(_ sender: UIButton) {
        if sender.tag == 0 {
            addLocality()
            selectAreaButton.tag = 1
            selectAreaButton.setImage(FWImage.checkBoxChecked, for: .normal)
        } else {
            removeLocality()
            selectAreaButton.tag = 0
            selectAreaButton.setImage(FWImage.checkBoxUnChecked, for: .normal)
        }

        let selectedLocalities = SelectedLocalities(
            selectedLocalityIDs: selectedLocalities,
            selectedSubLocalityIDs: selectedSubLocalities
        )
        selectAreaAction?(selectedLocalities)
    }

    func setupView(_ model: LocalityResponseData, _ indexPath: IndexPath){
        localityData = model
        self.indexPath = indexPath

        if indexPath.section == 1 {
            areaLabel.text = model.subLocality[indexPath.row].name
        }else if indexPath.section == 2, let units = model.unit {
            areaLabel.text = units[indexPath.row].unitName
        }
    }

    func addLocality(){
        guard let model = localityData, let indexPath = indexPath else { return }

        let subLocalityId = model.subLocality[indexPath.row].id
        selectedSubLocalities.append(subLocalityId)

        // If this is the first time, add the locality itself as well
        if !selectedLocalities.contains(model.id) {
            selectedLocalities.append(model.id)
        }
    }

    func removeLocality(){
        guard let model = localityData, let indexPath = indexPath else { return }

        let subLocalityId = model.subLocality[indexPath.row].id
        if let index = selectedSubLocalities.firstIndex(of: subLocalityId) {
            selectedSubLocalities.remove(at: index)
        }

        // If no sub-localities are selected for this locality, remove the locality
        if selectedSubLocalities.isEmpty, let localityIndex = selectedLocalities.firstIndex(of: model.id) {
            selectedLocalities.remove(at: localityIndex)
        }
    }
}
