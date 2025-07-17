//
//  NotificationLocalityViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 28/01/25.
//

import Foundation

final class NotificationLocalityViewModel {
    var localityData: LocalityResponseData!
    var allLocalities: [LocalityResponseData] = []
    var selectedNotificationArea: [SelectedNotificationModel] = []
    var selectedSubLocalities: [String] = []
    var selectedUnits: [String] = []
    var delegate: NotificationLocalityDelegate?

    // Save already selected notification locality/sub_locality/units/incident_type
    func saveAlreadySelectedArea() {
        guard !allLocalities.isEmpty else { return }

        for locality in allLocalities {
            let selectedSubLocalities = locality.subLocality.filter { $0.isChecked == true }

            var selectedUnits = [UnitDataModel?]()
            if let units = locality.unit, !units.isEmpty {
                selectedUnits = units.filter { $0!.isChecked == true }
            }

            var selectedIncidentTypes = [IncidentTypeModel?]()
            if let incidentType = locality.incidentType {
                selectedIncidentTypes = incidentType.filter { $0!.isChecked == true }
            }

            if !selectedSubLocalities.isEmpty ||
                !selectedUnits.isEmpty ||
                !selectedIncidentTypes.isEmpty
            {
                selectedSubLocalities.forEach { updateSelectionArrays(for: $0, forLocality: locality.id) }
                selectedUnits.forEach { updateSelectionArrays(for: $0, forLocality: locality.id) }
                selectedIncidentTypes.forEach { updateSelectionArrays(for: $0, forLocality: locality.id) }

                // Check if the locality is already in `selectedNotificationArea`
                if !selectedNotificationArea.contains(where: { $0.notificationId == locality.id && $0.type == "locality" }) {
                    let userId = FWUserDefaults().userID ?? ""
                    let selectedLocality = SelectedNotificationModel(userId: userId, notificationId: locality.id, type: "locality", forLocalityId: locality.id)
                    selectedNotificationArea.append(selectedLocality)
                }
            }
        }
    }

    func isLocalityAllChecked() -> Bool {
        if localityData != nil {
            return localityData.subLocality.allSatisfy { $0.isChecked }
        }
        return false
    }

    func toggleSelectAllSubLocalities() {
        let allSelected = localityData.subLocality.allSatisfy { $0.isChecked }

        if allSelected {
            localityData.isAllItemChecked = false
            for i in 0..<localityData.subLocality.count {
                localityData.subLocality[i].isChecked = false
                // Update selection arrays for the unselected sub-locality
                updateSelectionArrays(for: localityData.subLocality[i], forLocality: localityData.id)
            }
        } else {
            localityData.isAllItemChecked = true
            for i in 0..<localityData.subLocality.count {
                localityData.subLocality[i].isChecked = true
                // Update selection arrays for the selected sub-locality
                updateSelectionArrays(for: localityData.subLocality[i], forLocality: localityData.id)
            }
        }
    }

    func isUnitsAllChecked() -> Bool {
        if let units = localityData.unit {
            return units.compactMap { $0?.isChecked }.allSatisfy { $0 }
        }
        return false
    }

    func toggleSelectAllUnits() {
        guard let units = localityData.unit else { return }
        let allSelected = units.compactMap { $0?.isChecked }.allSatisfy { $0 }

        if allSelected {
            localityData.isAllItemChecked = false
            for i in 0..<units.count {
                if let unit = units[i], unit.isChecked {
                    localityData.unit?[i]?.isChecked = false
                    // Update selection arrays for the unselected units
                    updateSelectionArrays(for: localityData.unit?[i], forLocality: localityData.id)
                }
            }
        } else {
            localityData.isAllItemChecked = true
            for i in 0..<units.count {
                if let unit = units[i], !unit.isChecked {
                    localityData.unit?[i]?.isChecked = true
                    // Update selection arrays for the selected units
                    updateSelectionArrays(for: localityData.unit?[i], forLocality: localityData.id)
                }
            }
        }
    }

    func isIncidentTypeAllChecked() -> Bool {
        if let incidentTypes = localityData.incidentType {
            return incidentTypes.compactMap { $0?.isChecked }.allSatisfy { $0 }
        }
        return false
    }

    func toggleSelectAllIncidentTypes() {
        guard let incidentTypes = localityData.incidentType else { return }
        let allSelected = incidentTypes.compactMap { $0?.isChecked }.allSatisfy { $0 }

        if allSelected {
            localityData.isAllItemChecked = false
            for i in 0..<incidentTypes.count {
                if let incidentType = incidentTypes[i], incidentType.isChecked {
                    localityData.incidentType?[i]?.isChecked = false
                    // Update selection arrays for the unselected incident type
                    updateSelectionArrays(for: localityData.incidentType?[i], forLocality: localityData.id)
                }
            }
        } else {
            localityData.isAllItemChecked = true
            for i in 0..<incidentTypes.count {
                if let incidentType = incidentTypes[i], !incidentType.isChecked {
                    localityData.incidentType?[i]?.isChecked = true
                    // Update selection arrays for the selected incident type
                    updateSelectionArrays(for: localityData.incidentType?[i], forLocality: localityData.id)
                }
            }
        }
    }

    func updateSelectionArrayForChild(
        itemId: String,
        type: String,
        isChecked: Bool,
        localityId: String
    ) {
        let userId = FWUserDefaults().userID ?? ""

        let selectedItem = SelectedNotificationModel(
            userId: userId,
            notificationId: itemId,
            type: type,
            forLocalityId: localityId
        )

        let localityItem = SelectedNotificationModel(
            userId: userId,
            notificationId: localityId,
            type: "locality",
            forLocalityId: localityId
        )

        if isChecked {
            // Add child if not already present
            if !selectedNotificationArea.contains(where: { $0.notificationId == itemId }) {
                selectedNotificationArea.append(selectedItem)
            }

            // Add locality if not already present
            if !selectedNotificationArea.contains(where: { $0.type == "locality" && $0.notificationId == localityId }) {
                selectedNotificationArea.append(localityItem)
            }

        } else {
            // Remove child
            selectedNotificationArea.removeAll(where: { $0.notificationId == itemId })

            // Check if there are any remaining children for the same locality
            let childTypes: Set<String> = ["subLocality", "unit", "incidentType"]
            let hasOtherChildren = selectedNotificationArea.contains {
                childTypes.contains($0.type) && $0.forLocalityId == localityId
            }

            // If no more children for this locality, remove the locality too
            if !hasOtherChildren {
                selectedNotificationArea.removeAll(where: {
                    $0.type == "locality" && $0.notificationId == localityId
                })
            }
        }
    }

    func updateSelectionArrays(for subLocality: SubLocality, forLocality localityId: String) {
        updateSelectionArrayForChild(
            itemId: subLocality.id,
            type: "subLocality",
            isChecked: subLocality.isChecked,
            localityId: localityId
        )
    }

    func updateSelectionArrays(for unit: UnitDataModel?, forLocality localityId: String) {
        guard let unit else { return }

        updateSelectionArrayForChild(
            itemId: unit.id,
            type: "unit",
            isChecked: unit.isChecked,
            localityId: localityId
        )
    }

    func updateSelectionArrays(for incidentType: IncidentTypeModel?, forLocality localityId: String) {
        guard let incidentType else { return }

        updateSelectionArrayForChild(
            itemId: incidentType.id,
            type: "incidentType",
            isChecked: incidentType.isChecked,
            localityId: localityId
        )
    }

    func cleanUpLocalitySelections() {
        let childTypes: Set<String> = ["subLocality", "unit", "incidentType"]

        // Step 1: Get all locality IDs that have at least one child item selected
        let localityIdsReferencedByChildren = Set(
            selectedNotificationArea
                .filter { childTypes.contains($0.type) }
                .map { $0.forLocalityId }
        )

        // Step 2: Remove locality entries that don’t have any children
        selectedNotificationArea.removeAll { item in
            item.type == "locality" && !localityIdsReferencedByChildren.contains(item.notificationId)
        }
    }

    func setSelectedLocalities() {
        cleanUpLocalitySelections()

        let requestModel: [[String: Any]] = selectedNotificationArea.map { $0.toDictionary() }

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.setNotificationArea,
            payload: requestModel,
            expect: SuccessResponseModel.self
        ) { response, _, error in

            if let apiResponse = response as? SuccessResponseModel, apiResponse.code.lowercased() == "updated" {
                self.delegate?.setNotification(message: "Notification Settings updated successfully")
            } else if let errorMessage = error {
                self.delegate?.setNotification(message: errorMessage)
            }
        }
    }

    func toggleSelection(at indexPath: IndexPath) {
        if indexPath.section == 1, let localityData { // for sublocalities
            var subLocality = localityData.subLocality[indexPath.row]
            subLocality.isChecked.toggle()
            updateSelectionArrays(for: subLocality, forLocality: localityData.id)
            self.localityData.subLocality[indexPath.row] = subLocality
        } else if indexPath.section == 2, let units = localityData.unit {
            var unit = units[indexPath.row]
            unit?.isChecked.toggle()
            updateSelectionArrays(for: unit, forLocality: localityData.id)
            localityData.unit?[indexPath.row] = unit
        } else if indexPath.section == 3, let incidentType = localityData.incidentType {
            var incidentType = incidentType[indexPath.row]
            incidentType?.isChecked.toggle()
            updateSelectionArrays(for: incidentType, forLocality: localityData.id)
            localityData.incidentType?[indexPath.row] = incidentType
        }
    }
}
