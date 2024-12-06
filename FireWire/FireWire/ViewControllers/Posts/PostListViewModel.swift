//
//  PostListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 07/12/24.
//

import Foundation

final class PostListViewModel {

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
                debugPrint("incident list \(incidentListResponse.data.count)")
            }else{
                print("Invalid response object")
            }
        }
    }
}
