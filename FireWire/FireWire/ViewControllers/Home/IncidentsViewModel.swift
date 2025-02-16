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

    init(_ incidentList: [IncidentDataModel] = [], _ selectedLocalities: SelectedLocalities? = nil) {
        self.selectedLocalities = selectedLocalities
        getIncidentList(selectedLocalities: selectedLocalities)
    }

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

            if error != nil && self?.delegate != nil{
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
        for item in data {
            // Append new items to existing list
            if !items.contains(where: { $0.id == item.id }) {
                items.append(item)

                // for map markers
                if let lat = Double(item.latitude), let lon = Double(item.longitude) {
                    let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    let mapModel = MapMarkerModel(coordinates: coordinates, address: item.address, markerType: .incident)
                    self.markersList.append(mapModel)
                }
            }
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

    func favouriteIncident(incidentId: String, like: Bool, completion: @escaping (Bool) -> Void){

        let requestModel = APIPayload.favouriteIncident(
            userId: UserDefaults.standard.string(forKey: "user_id") ?? "",
            incidentId: incidentId,
            type: like == true ? "unlike" : "like"
        ).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.favIncident,
            payload: requestModel as JSON,
            expect: SuccessResponseModel.self)
        {response, _, _ in

            guard let apiResponse = response as? SuccessResponseModel else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self.delegate?.error(message: errorMessage)
                return
            }

            if apiResponse.code == "unlike_success" || apiResponse.code == "like_success" {
                completion(true)
            }else{
                self.delegate?.error(message: apiResponse.message)
            }

        }
    }
}
