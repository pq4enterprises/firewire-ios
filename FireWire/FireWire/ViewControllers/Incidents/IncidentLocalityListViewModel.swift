//
//  IncidentLocalityListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 18/12/24.
//

import Foundation

enum LocalityListType: String {
    case area
    case notification
}

final class IncidentLocalityListViewModel {
    var localityData: [LocalityResponseData] = []
    var delegate: IncidentLocalityListViewDelegate?
    var selectAreaDelegate: SelectAreaDelegate?
    var feedAreaDelegate: FeedAreaDelegate?
    var filterAreaDelegate: FilterAreaDelegate?

    var selectedAreas: [SelectedAreaModel] = []
    var selectedLocalities: [String] = []
    var selectedSubLocalities: [String] = []

    func getLocalities(forType type: LocalityListType) {
        var requestModel = IncidentLocalityRequestModel(sortBy: "createdAt", sortDir: "desc", offset: 1, limit: 10)
        requestModel.listType = ListType(type: type.rawValue)

        let getIncidentLocalityRequestModel = APIPayload.incidentLocalityList(requestModel).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.localityList,
            payload: getIncidentLocalityRequestModel,
            expect: LocalityResponseModel.self,
            requestType: APIConstants.GET)
        { [weak self] response, _, error in

            if let errorMessage = error {
                if self?.selectAreaDelegate != nil {
                    self?.selectAreaDelegate?.error(message: errorMessage)
                } else {
                    self?.delegate?.error(message: errorMessage)
                }
                return
            }

            guard let localityResponse = response as? LocalityResponseModel else {
                let errorMessage = (response == nil) ? .CommonError.techError : "Unexpected response format"
                if self?.selectAreaDelegate != nil {
                    self?.selectAreaDelegate?.error(message: errorMessage)
                } else {
                    self?.delegate?.error(message: errorMessage)
                }
                return
            }

            guard let localityData = localityResponse.data else {
                if self?.selectAreaDelegate != nil {
                    self?.selectAreaDelegate?.error(message: .CommonError.techError)
                } else {
                    self?.delegate?.error(message: .CommonError.techError)
                }
                return
            }

            self?.localityData = localityData.data
            self?.saveSelectedArea()
            self?.delegate?.dataReceived()
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
        let requestModel: [[String: Any]] = selectedAreas.map { $0.toDictionary() }
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.setSelectedArea,
            payload: requestModel,
            expect: SuccessResponseModel.self)
        { [weak self] response, _, _ in

            if let apiResponse = response as? SuccessResponseModel, apiResponse.code.lowercased() == "updated" {
                if self?.selectAreaDelegate != nil {
                    self?.selectAreaDelegate?.confirmSelectArea()
                }

                if self?.feedAreaDelegate != nil {
                    self?.feedAreaDelegate?.savedFeedArea()
                }

                if self?.filterAreaDelegate != nil {
                    self?.filterAreaDelegate?.filterUpdate()
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
        let userId = FWUserDefaults().userID ?? ""
        let selectedArea = SelectedAreaModel(userId: userId, localityId: localityId, subLocalityId: subLocality.id)

        if subLocality.isChecked {
            // If the sub-locality is selected, add it to the selected areas if not already present
            if !selectedAreas.contains(where: { $0.subLocalityId == subLocality.id && $0.localityId == localityId }) {
                selectedAreas.append(selectedArea)
            }
        } else {
            // If the sub-locality is de-selected, remove it from the selected areas
            if let index = selectedAreas.firstIndex(where: { $0.subLocalityId == subLocality.id && $0.localityId == localityId }) {
                selectedAreas.remove(at: index)
            }
        }
    }

    func isLocalityAllChecked(section: Int) -> Bool {
        if !localityData.isEmpty {
            return localityData[section].subLocality.allSatisfy { $0.isChecked }
        }
        return false
    }

    // Handle "Select All" for a section
    func toggleSelectAll(forSection section: Int) {
        let allSelected = localityData[section].subLocality.allSatisfy { $0.isChecked }

        if allSelected {
            localityData[section].isAllItemChecked = false
            for i in 0..<localityData[section].subLocality.count {
                localityData[section].subLocality[i].isChecked = false
                // Update selection arrays for the unselected sub-locality and its locality
                updateSelectionArrays(for: localityData[section].subLocality[i], localityId: localityData[section].id)
            }
        } else {
            localityData[section].isAllItemChecked = true
            for i in 0..<localityData[section].subLocality.count {
                localityData[section].subLocality[i].isChecked = true
                // Update selection arrays for the selected sub-locality and its locality
                updateSelectionArrays(for: localityData[section].subLocality[i], localityId: localityData[section].id)
            }
        }

//        /// If not all selected, select all items
//        if !allSelected {
//            for i in 0..<localityData[section].subLocality.count {
//                let subLocality = localityData[section].subLocality[i]
//                if !subLocality.isChecked {
//                    localityData[section].subLocality[i].isChecked = true
//                    // Update selection arrays for the selected sub-locality and its locality
//                    updateSelectionArrays(for: localityData[section].subLocality[i], localityId: localityData[section].id)
//                }
//            }
//        }
    }

    // To get selected IDs at any point
    func getSelectedIds() -> SelectedLocalities {
        return SelectedLocalities(selectedLocalityIDs: selectedLocalities, selectedSubLocalityIDs: selectedSubLocalities)
    }
}
