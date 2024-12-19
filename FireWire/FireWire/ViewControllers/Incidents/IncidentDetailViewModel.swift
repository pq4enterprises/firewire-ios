//
//  IncidentDetailViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 10/12/24.
//

import Foundation

final class IncidentDetailViewModel {
    var incidentDetail: IncidentDetailModel?
    var delegate: IncidentDetailViewDelegate?

    func getIncidentDetail(for incidentID: String) {
        let requestURL = String.init(format: APIEndpoints.incidentDetail, incidentID)

        APIRequest().callGetApi(
            apiEndPoint: requestURL,
            parameters: nil,
            expect: IncidentDetailResponseModel.self)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if let incidentDetailResponse = apiResponse as? IncidentDetailResponseModel {
                self?.incidentDetail = incidentDetailResponse.data[0]
                self?.delegate?.dataReceived()
            }else{
                print("Invalid response object")
            }
        }
    }

    func favouriteIncident(like: Bool){
        guard let incidentDetail = incidentDetail else { return }

        let requestModel = APIPayload.favouriteIncident(
            userId: UserDefaults.standard.string(forKey: "user_id") ?? "",
            incidentId: incidentDetail.id,
            type: like == true ? "like" : "unlike"
        ).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.favIncident,
            payload: requestModel as JSON,
            expect: SuccessResponseModel.self)
        {response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if apiResponse is SuccessResponseModel {
                self.delegate?.incidentFavourited(like: like)
            }
        }
    }
}
