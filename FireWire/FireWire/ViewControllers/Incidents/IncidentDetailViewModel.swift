//
//  IncidentDetailViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 10/12/24.
//

import Foundation

final class IncidentDetailViewModel {
    var incidentDetail: IncidentDetailModel?
    var delegate: PostDetailViewDelegate?

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
}
