//
//  IncidentLocalityListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 18/12/24.
//

import Foundation

final class IncidentLocalityListViewModel {
    var localityData: [LocalityResponseData] = []
    var delegate: IncidentLocalityListViewDelegate?
    var selectAreaDelegate: SelectAreaDelegate?

    var selectedAreas: [SelectedAreaModel] = []
    var selectedLocalities: [String] = []
    var selectedSubLocalities: [String] = []

    func getLocalities() {
        var requestModel = IncidentLocalityRequestModel(sortBy: "createdAt", sortDir: "desc", offset: 1, limit: 10)
        requestModel.listType = ListType(type: "area")

        let getIncidentLocalityRequestModel = APIPayload.incidentLocalityList(requestModel).toDictionary()


        APIRequest().callApi(
            apiEndPoint: APIEndpoints.localityList,
            payload: getIncidentLocalityRequestModel,
            expect: LocalityResponseModel.self,
            requestType: APIConstants.GET)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if let localityResponse = apiResponse as? LocalityResponseModel {
                self?.localityData = localityResponse.data.data
                self?.saveSelectedArea()
                self?.delegate?.dataReceived()
            }else{
                print("Invalid response object")
            }
        }
    }

    func saveSelectedArea() {
        for locality in localityData where !locality.subLocality.isEmpty {
            for subLocality in locality.subLocality {
                updateSelectionArrays(for: subLocality, localityId: locality.id)
            }
        }
    }

    func setSelectedLocalities() {
        if !selectedAreas.isEmpty {
            let requestModel: [[String: Any]] = selectedAreas.map { $0.toDictionary() }
            APIRequest().callApi(
                apiEndPoint: APIEndpoints.setSelectedArea,
                payload:  requestModel,
                expect: SuccessResponseModel.self)
            { [weak self] response, _, _ in

                if let apiResponse = response as? SuccessResponseModel, apiResponse.code.lowercased() == "updated"{
                    if self?.selectAreaDelegate != nil {
                        self?.selectAreaDelegate?.confirmSelectArea()
                    }
                }
            }
        }
    }

    func toggleSelection(at indexPath: IndexPath) {
        var subLocality = localityData[indexPath.section].subLocality[indexPath.row]
        subLocality.isChecked.toggle()
        updateSelectionArrays(for: subLocality, localityId: localityData[indexPath.section].id)
        localityData[indexPath.section].subLocality[indexPath.row] = subLocality
    }

    func updateSelectionArrays(for subLocality: SubLocality, localityId: String) {
        // Create an area model for the selected sub-locality and locality
        let userId = UserDefaults.standard.string(forKey: "user_id") ?? ""
        let selectedArea = SelectedAreaModel(userId: userId, localityId: localityId, subLocalityId: subLocality.id)

        if subLocality.isChecked {
            // If the sub-locality is selected, add it to the selected areas if not already present
            if !selectedAreas.contains(where: { $0.subLocalityId == subLocality.id && $0.localityId == localityId}) {
                selectedAreas.append(selectedArea)
            }
        } else {
            // If the sub-locality is de-selected, remove it from the selected areas
            if let index = selectedAreas.firstIndex(where: { $0.subLocalityId == subLocality.id && $0.localityId == localityId}) {
                selectedAreas.remove(at: index)
            }
        }

    }


//    // Update the selectedLocalities and selectedSubLocalities arrays when an item is selected/deselected
//    func updateSelectionArrays(for subLocality: SubLocality, localityId: String) {
//        // Update selected sub-localities
//        if subLocality.isSelected {
//            if !selectedSubLocalities.contains(subLocality.id) {
//                selectedSubLocalities.append(subLocality.id)
//            }
//        } else {
//            if let index = selectedSubLocalities.firstIndex(of: subLocality.id) {
//                selectedSubLocalities.remove(at: index)
//            }
//        }
//
//        // Update selected localities (only if sub-localities are selected)
//        if subLocality.isSelected {
//            // If this sub-locality is selected, add the locality ID to the selected localities
//            if !selectedLocalities.contains(localityId) {
//                selectedLocalities.append(localityId)
//            }
//        } else {
//            // If no sub-localities are selected for this locality, remove the locality ID
//            let isAnySubLocalitySelected = localityData.contains { locality in
//                locality.subLocality.contains { $0.isSelected && $0.id != subLocality.id }
//            }
//            if !isAnySubLocalitySelected, let localityIndex = selectedLocalities.firstIndex(of: localityId) {
//                selectedLocalities.remove(at: localityIndex)
//            }
//        }
//    }

    // Handle "Select All" for a section
    func toggleSelectAll(forSection section: Int) {
        let allSelected = localityData[section].subLocality.allSatisfy { $0.isChecked }

        /// If not all selected, select all items
        if !allSelected {
            for i in 0..<localityData[section].subLocality.count {
                let subLocality = localityData[section].subLocality[i]
                if !subLocality.isChecked {
                    localityData[section].subLocality[i].isChecked = true
                    // Update selection arrays for the selected sub-locality and its locality
                    updateSelectionArrays(for: localityData[section].subLocality[i], localityId: localityData[section].id)
                }
            }
        }
    }

    // To get selected IDs at any point
    func getSelectedIds() -> SelectedLocalities {
        return SelectedLocalities(selectedLocalityIDs: selectedLocalities, selectedSubLocalityIDs: selectedSubLocalities)
    }
}
