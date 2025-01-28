//
//  NotificationLocalityViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 28/01/25.
//

import Foundation

final class NotificationLocalityViewModel {
    var localityData: LocalityResponseData!
    var selectedSubLocalities: [String] = []
    var selectedUnits: [String] = []

    func toggleSelectAllSubLocalities() {
        let allSelected = localityData.subLocality.allSatisfy { $0.isSelected }

        /// If not all selected, select all items
        if !allSelected {
            for i in 0..<localityData.subLocality.count {
                let subLocality = localityData.subLocality[i]
                if !subLocality.isSelected {
                    localityData.subLocality[i].isSelected = true
                    // Update selection arrays for the selected sub-locality
                    updateSelectionArrays(for: localityData.subLocality[i])
                }
            }
        }
    }

    func toggleSelectAllUnits() {
        guard let units = localityData.unit else { return }
        let allSelected = units.allSatisfy { $0.isChecked }

        /// If not all selected, select all items
        if !allSelected {
            for i in 0..<units.count {
                let unit = units[i]
                if !unit.isChecked {
                    localityData.unit?[i].isChecked = true
                    // Update selection arrays for the selected units
                    updateSelectionArrays(for: localityData.unit?[i])
                }
            }
        }
    }

    // Update the selectedLocalities and selectedSubLocalities arrays when an item is selected/deselected
    func updateSelectionArrays(for subLocality: SubLocality) {
        // Update selected sub-localities
        if subLocality.isSelected {
            if !selectedSubLocalities.contains(subLocality.id) {
                selectedSubLocalities.append(subLocality.id)
            }
        } else {
            if let index = selectedSubLocalities.firstIndex(of: subLocality.id) {
                selectedSubLocalities.remove(at: index)
            }
        }
    }

    func updateSelectionArrays(for unit: UnitDataModel?) {
        guard let unit else { return }
        
        if unit.isChecked {
            if !selectedUnits.contains(unit.id) {
                selectedUnits.append(unit.id)
            }
        } else {
            if let index = selectedUnits.firstIndex(of: unit.id) {
                selectedUnits.remove(at: index)
            }
        }
    }

    func toggleSelection(at indexPath: IndexPath) {
        if indexPath.section == 1, let localityData { // for sublocalities
            var subLocality = localityData.subLocality[indexPath.row]
            subLocality.isSelected.toggle()
            updateSelectionArrays(for: subLocality)
            self.localityData.subLocality[indexPath.row] = subLocality
        } else if indexPath.section == 2, let units = localityData.unit {
            var unit = units[indexPath.row]
            unit.isChecked.toggle()
            updateSelectionArrays(for: unit)
            self.localityData.unit?[indexPath.row] = unit
        }
    }
}
