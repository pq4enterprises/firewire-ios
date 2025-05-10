//
//  IncidentsViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 09/02/25.
//

import Foundation
import MapKit

final class IncidentsViewModel: PaginatableViewModel {
    typealias DataType = IncidentDataModel

    var currentPage: Int = 1
    var totalPages: Int = 1
    var limit: Int = 10
    var items: [IncidentDataModel] = []
    var markersList: [MapMarkerModel] = []

    var selectedLocalities: SelectedLocalities?
    var delegate: IncidentsViewViewDelegate?

    func fetchData(forPage page: Int, completion: @escaping (Result<[IncidentDataModel], any Error>) -> Void) {
        var requestModel = IncidentRequestModel(sortBy: "createdAt", sortDir: "desc", offset: page, limit: limit)

        // Add filters if available
        if let selectedLocalities = selectedLocalities {
            requestModel.query = QueryModel(
                locality: selectedLocalities.selectedLocalityIDs,
                subLocality: selectedLocalities.selectedSubLocalityIDs
            )
        }

        let getIncidentRequestModel = APIPayload.incidentList(requestModel).toDictionary()

        // Perform API call
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.incidentList,
            payload: getIncidentRequestModel,
            expect: IncidentResponseModel.self,
            requestType: APIConstants.GET
        ) { [weak self] response, _, error in

            if error != nil && self?.delegate != nil {
                self?.delegate?.tokenExpired()
                return
            }

            guard let apiResponse = response else {
                self?.delegate?.noIncidentData()
                return
            }

            if let incidentListResponse = apiResponse as? IncidentResponseModel {
                let newItems = incidentListResponse.data.data
                self?.totalPages = incidentListResponse.data.pageInfo.totalCount
                completion(.success(newItems))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
            }
        }
    }

    func didFetchData(_ data: [IncidentDataModel]) {
        var updatedMarkers: [MapMarkerModel] = []

        for item in data {
            // if the item already exists in the list update the existing item at the same position
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            } else {
                items.append(item)
            }

            // for map markers
            if let lat = Double(item.latitude), let lon = Double(item.longitude) {
                let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)

                /// snippet for map icon:  field3value + sub locality name - Not using for now, instead showing full address
                var address = item.field3Value
                if let subLocalityName = item.subLocality.first?.name, !subLocalityName.isEmpty {
                    if !address.isEmpty {
                        address.append(", ")
                    }
                    address.append(subLocalityName)
                }

                let mapModel = MapMarkerModel(
                    incidentId: item.id,
                    coordinates: coordinates,
                    title: item.field1Value,
                    address: item.address,
                    markerType: .incident,
                    createdAt: item.createdAt
                )

                updatedMarkers.append(mapModel)
            }

            markersList = updatedMarkers
        }

        if items.count > 0 && updatedMarkers.count > 0 {
            items.sort { $0.createdAt > $1.createdAt }
            updatedMarkers.sort { $0.createdAt > $1.createdAt }
        }

        items.count > 0
            ? delegate?.incidentDataLoaded()
            : delegate?.noIncidentData()
    }

    // Public method to trigger data fetching
    func getIncidentList(selectedLocalities: SelectedLocalities? = nil) {
        fetchData(forPage: currentPage) { [weak self] result in
            switch result {
            case .success(let newItems):
                self?.didFetchData(newItems)
            case .failure(let error):
                print("Error fetching incidents: \(error)")
            }
        }
    }

    func favouriteIncident(incidentId: String, like: Bool, completion: @escaping (Bool) -> Void) {
        let requestModel = APIPayload.favouriteIncident(
            userId: FWUserDefaults().userID ?? "",
            incidentId: incidentId,
            type: like == true ? "unlike" : "like"
        ).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.favIncident,
            payload: requestModel as JSON,
            expect: SuccessResponseModel.self
        ) { response, _, error in
            if let errorMessage = error {
                self.delegate?.error(message: errorMessage)
                return
            }
            guard let apiResponse = response as? SuccessResponseModel else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self.delegate?.error(message: errorMessage)
                return
            }

            if apiResponse.code == "unlike_success" || apiResponse.code == "like_success" {
                completion(true)
            } else {
                self.delegate?.error(message: apiResponse.message)
            }
        }
    }

    func getSelectedIncidentIdFromMapTitle(title: String) -> String? {
        markersList.first { $0.title.lowercased() == title.lowercased() }?.incidentId
    }

    func validateIfAreaSelected(forType type: LocalityListType, completion: @escaping (Bool) -> Void) {
        var requestModel = IncidentLocalityRequestModel(sortBy: "createdAt", sortDir: "desc", offset: 1, limit: 10)
        requestModel.listType = ListType(type: type.rawValue)

        let getIncidentLocalityRequestModel = APIPayload.incidentLocalityList(requestModel).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.localityList,
            payload: getIncidentLocalityRequestModel,
            expect: LocalityResponseModel.self,
            requestType: APIConstants.GET
        ) { response, _, error in

            guard let localityResponse = response as? LocalityResponseModel,
                  let localityData = localityResponse.data
            else {
                completion(false)
                return
            }

            let isAnyAreaSelected = localityData.data.contains { locality in
                locality.subLocality.contains { $0.isChecked } ||
                    (locality.unit?.compactMap { $0?.isChecked }.contains(true) ?? false) ||
                    (locality.incidentType?.compactMap { $0?.isChecked }.contains(true) ?? false)
            }
            completion(isAnyAreaSelected)
        }
    }
}
