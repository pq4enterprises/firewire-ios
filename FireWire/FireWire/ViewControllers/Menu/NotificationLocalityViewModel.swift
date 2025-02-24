//
//  NotificationLocalityViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 28/01/25.
//

import Foundation

final class NotificationLocalityViewModel {
    var localityData: LocalityResponseData!
    var selectedNotificationArea: [SelectedNotificationModel] = []
    var selectedSubLocalities: [String] = []
    var selectedUnits: [String] = []
    var delegate: NotificationLocalityDelegate?

    func toggleSelectAllSubLocalities() {
        let allSelected = localityData.subLocality.allSatisfy { $0.isChecked }

        /// If not all selected, select all items
        if !allSelected {
            for i in 0..<localityData.subLocality.count {
                let subLocality = localityData.subLocality[i]
                if !subLocality.isChecked {
                    localityData.subLocality[i].isChecked = true
                    // Update selection arrays for the selected sub-locality
                    updateSelectionArrays(for: localityData.subLocality[i])
                }
            }
        }
    }

    func toggleSelectAllUnits() {
        guard let units = localityData.unit else { return }
        let allSelected = units.compactMap { $0?.isChecked }.allSatisfy { $0 }

        /// If not all selected, select all items
        if !allSelected {
            for i in 0..<units.count {
                if let unit = units[i], !unit.isChecked {
                    localityData.unit?[i]?.isChecked = true
                    // Update selection arrays for the selected units
                    updateSelectionArrays(for: localityData.unit?[i])
                }
            }
        }
    }

    func toggleSelectAllIncidentTypes() {
        guard let incidentTypes = localityData.incidentType else { return }
        let allSelected = incidentTypes.compactMap { $0?.isChecked }.allSatisfy { $0 }

        /// If not all selected, select all items
        if !allSelected {
            for i in 0..<incidentTypes.count {
                if let incidentType = incidentTypes[i], !incidentType.isChecked {
                    localityData.incidentType?[i]?.isChecked = true
                    // Update selection arrays for the selected incident type
                    updateSelectionArrays(for: localityData.incidentType?[i])
                }
            }
        }
    }

    func updateSelectionArrays(for subLocality: SubLocality) {
        // Create an area model for the selected sub-locality and locality
        let userId = UserDefaults.standard.string(forKey: "user_id") ?? ""
        let selectedArea = SelectedNotificationModel(userId: userId, notificationId: subLocality.id, type: "subLocality")

        if subLocality.isChecked {
            // If the sub-locality is selected, add it to the selected areas if not already present
            if !selectedNotificationArea.contains(where: { $0.notificationId == subLocality.id }) {
                selectedNotificationArea.append(selectedArea)
            }
        } else {
            // If the sub-locality is de-selected, remove it from the selected areas
            if let index = selectedNotificationArea.firstIndex(where: { $0.notificationId == subLocality.id }) {
                selectedNotificationArea.remove(at: index)
            }
        }
    }

    func updateSelectionArrays(for unit: UnitDataModel?) {
        guard let unit else { return }

        let userId = UserDefaults.standard.string(forKey: "user_id") ?? ""
        let selectedArea = SelectedNotificationModel(userId: userId, notificationId: unit.id, type: "unit")

        if unit.isChecked {
            if !selectedNotificationArea.contains(where: { $0.notificationId == unit.id }) {
                selectedNotificationArea.append(selectedArea)
            }
        } else {
            if let index = selectedNotificationArea.firstIndex(where: { $0.notificationId == unit.id }) {
                selectedNotificationArea.remove(at: index)
            }
        }
    }

    func updateSelectionArrays(for incidentType: IncidentTypeModel?) {
        guard let incidentType else { return }

        let userId = UserDefaults.standard.string(forKey: "user_id") ?? ""
        let selectedArea = SelectedNotificationModel(userId: userId, notificationId: incidentType.id, type: "incident_type")

        if incidentType.isChecked {
            if !selectedNotificationArea.contains(where: { $0.notificationId == incidentType.id }) {
                selectedNotificationArea.append(selectedArea)
            }
        } else {
            if let index = selectedNotificationArea.firstIndex(where: { $0.notificationId == incidentType.id }) {
                selectedNotificationArea.remove(at: index)
            }
        }
    }

    func setSelectedLocalities() {
        if !selectedNotificationArea.isEmpty {
            let requestModel: [[String: Any]] = selectedNotificationArea.map { $0.toDictionary() }
            APIRequest().callApi(
                apiEndPoint: APIEndpoints.setNotificationArea,
                payload: requestModel,
                expect: SuccessResponseModel.self)
            { response, _, _ in

                if let apiResponse = response as? SuccessResponseModel, apiResponse.code.lowercased() == "updated" {
                    self.delegate?.setNotification(message: apiResponse.message)
                }
            }
        }
    }

//    // Update the selectedLocalities and selectedSubLocalities arrays when an item is selected/deselected
//    func updateSelectionArrays(for subLocality: SubLocality) {
//        // Update selected sub-localities
//        if subLocality.isChecked {
//            if !selectedSubLocalities.contains(subLocality.id) {
//                selectedSubLocalities.append(subLocality.id)
//            }
//        } else {
//            if let index = selectedSubLocalities.firstIndex(of: subLocality.id) {
//                selectedSubLocalities.remove(at: index)
//            }
//        }
//    }

//    func updateSelectionArrays(for unit: UnitDataModel?) {
//        guard let unit else { return }
//
//        if unit.isChecked {
//            if !selectedUnits.contains(unit.id) {
//                selectedUnits.append(unit.id)
//            }
//        } else {
//            if let index = selectedUnits.firstIndex(of: unit.id) {
//                selectedUnits.remove(at: index)
//            }
//        }
//    }

    func toggleSelection(at indexPath: IndexPath) {
        if indexPath.section == 1, let localityData { // for sublocalities
            var subLocality = localityData.subLocality[indexPath.row]
            subLocality.isChecked.toggle()
            updateSelectionArrays(for: subLocality)
            self.localityData.subLocality[indexPath.row] = subLocality
        } else if indexPath.section == 2, let units = localityData.unit {
            var unit = units[indexPath.row]
            unit?.isChecked.toggle()
            updateSelectionArrays(for: unit)
            localityData.unit?[indexPath.row] = unit
        } else if indexPath.section == 3, let incidentType = localityData.incidentType {
            var incidentType = incidentType[indexPath.row]
            incidentType?.isChecked.toggle()
            updateSelectionArrays(for: incidentType)
            localityData.incidentType?[indexPath.row] = incidentType
        }
    }
}
