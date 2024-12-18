//
//  IncidentListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 07/12/24.
//

import Foundation

final class IncidentListViewModel {

    var incidentList: [IncidentDataModel] = []
    //var delegate: PostListViewDelegate?

    init(_ incidentList: [IncidentDataModel]) {
        self.incidentList = incidentList
        //getIncidentList()
    }

    func getIncidentList() {
        let parameters: [String: Any] = ["sortDir": "desc", "offset": 1, "limit": 10]

        APIRequest().callGetApi(
            apiEndPoint: APIEndpoints.incidentList,
            parameters: parameters,
            expect: IncidentResponseModel.self)
        { [weak self] response, _, _ in
            
            guard let apiResponse = response else {
                return
            }

            if let incidentListResponse = apiResponse as? IncidentResponseModel {
                self?.incidentList = incidentListResponse.data.data
                //self?.delegate?.dataReceived()
            }else{
                print("Invalid response object")
            }
        }
    }
}
