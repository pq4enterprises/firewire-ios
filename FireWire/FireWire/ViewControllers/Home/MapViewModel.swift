//
//  MapViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import Foundation
import MapKit

final class MapViewModel {
    //    var markersList: [CLLocationCoordinate2D] = [
    //        CLLocationCoordinate2D(latitude: 39.1878056, longitude: -76.63167709999999),
    //        CLLocationCoordinate2D(latitude: 32.9668022, longitude: -117.0898602)
    //    ]

    var incidentList: [IncidentDataModel] = []
    var markersList: [MapMarkerModel] = []
    var delegate: MapViewDelegate?

    init() {
        getIncidentList()
    }

    func getIncidentList() {
        let requestModel = IncidentRequestModel(sortBy: "createdAt", sortDir: "desc", offset: 1, limit: 10)
        let getIncidentRequestModel = APIPayload.incidentList(requestModel).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.incidentList,
            payload: getIncidentRequestModel,
            expect: IncidentResponseModel.self,
            requestType: APIConstants.GET)
        { [weak self] response, _, error in

            if error != nil {
                self?.delegate?.tokenExpired()
                return
            }

            guard let apiResponse = response else {
                return
            }

            if let incidentListResponse = apiResponse as? IncidentResponseModel {
                let incidentList = incidentListResponse.data.data
                self?.incidentList = incidentList

                self?.frameMarkerCoordinates(incidentList: incidentList)
            } else {
                print("Invalid response object")
            }
        }
    }

    func frameMarkerCoordinates(incidentList: [IncidentDataModel]){
        for item in incidentList {
            if let lat = Double(item.latitude), let lon = Double(item.longitude) {
                let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let mapModel = MapMarkerModel(coordinates: coordinates, address: item.address, markerType: .incident)
                self.markersList.append(mapModel)
                self.delegate?.dataReceived()
            }
        }
    }
}
