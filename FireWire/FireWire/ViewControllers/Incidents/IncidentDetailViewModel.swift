//
//  IncidentDetailViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 10/12/24.
//

import Foundation
import MapKit

final class IncidentDetailViewModel {
    var incidentDetail: IncidentDetailModel?
    var delegate: IncidentDetailViewDelegate?
    var markersList: [MapMarkerModel] = []

    func getIncidentDetail(for incidentID: String) {
        let requestURL = String(format: APIEndpoints.incidentDetail, incidentID)

        APIRequest().callApi(
            apiEndPoint: requestURL,
            expect: IncidentDetailResponseModel.self,
            requestType: APIConstants.GET)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if let incidentDetailResponse = apiResponse as? IncidentDetailResponseModel {
                self?.incidentDetail = incidentDetailResponse.data[0]
                self?.createMarkerCoordinates(incidentDetail: incidentDetailResponse.data[0])
            } else {
                print("Invalid response object")
            }
        }
    }

    func createMarkerCoordinates(incidentDetail: IncidentDetailModel) {
        if let lat = Double(incidentDetail.latitude), let lon = Double(incidentDetail.longitude) {
            let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let mapModel = MapMarkerModel(coordinates: coordinates, address: incidentDetail.address, markerType: .incident)
            self.markersList.append(mapModel)
        }

        if let points = incidentDetail.points {
            for point in points {
                if let latitude = point.latitude, let longitude = point.longitude, let lat = Double(latitude), let lon = Double(longitude) {
                    let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    let mapModel = MapMarkerModel(coordinates: coordinates, address: point.address ?? "", markerType: .points)
                    self.markersList.append(mapModel)
                }
            }
        }
        self.delegate?.dataReceived()
    }

    func postIncidentDetailViewCount() {
        guard let incidentDetail = incidentDetail else { return }

        let requestModel = APIPayload.favouriteIncident(
            userId: UserDefaults.standard.string(forKey: "user_id") ?? "",
            incidentId: incidentDetail.id,
            type: "view").toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.favIncident,
            payload: requestModel as JSON,
            expect: SuccessResponseModel.self)
        { response, _, _ in

            guard let apiResponse = response as? SuccessResponseModel else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self.delegate?.error(message: errorMessage)
                return
            }

            if apiResponse.code != "success" {
                self.delegate?.error(message: apiResponse.message)
            }
        }
    }

    func favouriteIncident(like: Bool) {
        guard let incidentDetail = incidentDetail else { return }

        let requestModel = APIPayload.favouriteIncident(
            userId: UserDefaults.standard.string(forKey: "user_id") ?? "",
            incidentId: incidentDetail.id,
            type: like == true ? "unlike" : "like").toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.favIncident,
            payload: requestModel as JSON,
            expect: SuccessResponseModel.self)
        { response, _, _ in

            guard let apiResponse = response as? SuccessResponseModel else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self.delegate?.error(message: errorMessage)
                return
            }

            if apiResponse.code == "like_success" {
                self.delegate?.incidentFavourited(like: true)
            }else if apiResponse.code == "unlike_success" {
                self.delegate?.incidentFavourited(like: false)
            }else{
                self.delegate?.error(message: apiResponse.message)
            }
        }
    }
}
