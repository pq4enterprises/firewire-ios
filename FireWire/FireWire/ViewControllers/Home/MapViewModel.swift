//
//  MapViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 15/12/24.
//

import Foundation
import MapKit

final class MapViewModel {
    // var incidentList: [IncidentDataModel] = []
    var markersList: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 39.1878056, longitude: -76.63167709999999),
        CLLocationCoordinate2D(latitude: 32.9668022, longitude: -117.0898602)
    ]

    init() {
        getIncidentList()
    }

    func getIncidentList() {
        let parameters: [String: Any] = ["sortBy": "createdAt", "sortDir": "desc", "offset": 1, "limit": 10]

        APIRequest().callGetApi(
            apiEndPoint: APIEndpoints.incidentList,
            parameters: parameters,
            expect: IncidentResponseModel.self)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if let incidentListResponse = apiResponse as? IncidentResponseModel {
                let incidentList = incidentListResponse.data.data
//                for item in incidentList {
//                    if let latitude = item.locality.latitude, let longitude = item.locality.longitude {
//                        if let lat = Double(latitude), let lon = Double(longitude) {
//                            let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
//                            self?.markersList.append(coordinates)
//                        }
//                    }
//                }
            } else {
                print("Invalid response object")
            }
        }
    }
}
