//
//  PostDetailViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 10/12/24.
//

import Foundation

final class PostDetailViewModel {

    var incidentDetail: IncidentDetailResponseModel?
    var delegate: PostDetailViewDelegate?

    init(incidentID: String) {
        getIncidentDetail(for: incidentID)
    }

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
                self?.incidentDetail = incidentDetailResponse
                self?.delegate?.dataReceived()
            }else{
                print("Invalid response object")
            }
        }
    }
}
