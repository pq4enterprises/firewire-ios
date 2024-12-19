//
//  IncidentListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 07/12/24.
//

import Foundation

final class IncidentListViewModel {

    var incidentList: [IncidentDataModel] = []
    var delegate: PostListViewDelegate?

    init(_ incidentList: [IncidentDataModel] = [], _ selectedLocalities: SelectedLocalities? = nil) {
        if incidentList.count > 0 {
            self.incidentList = incidentList
        }else{
            filterIncidentList(selectedLocalities: selectedLocalities)
        }
    }

    func filterIncidentList(selectedLocalities: SelectedLocalities?) {

        var parameters: [String: Any] = ["sortDir": "desc", "offset": 1, "limit": 10]

        if let selectedLocalities {
            parameters["query"] = [
                "locality": selectedLocalities.selectedLocalityIDs,
                "subLocality": selectedLocalities.selectedSubLocalityIDs
            ]
        }

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
                self?.delegate?.filterDataReceived()
            }else{
                print("Invalid response object")
            }
        }
    }

    func frameAndPassQuery(_ selectedLocalities: SelectedLocalities) -> String{
        let query: [String: Any] = [
            "locality": selectedLocalities.selectedLocalityIDs,
            "subLocality": selectedLocalities.selectedSubLocalityIDs
        ]

        if let queryData = try? JSONSerialization.data(withJSONObject: query, options: []),
               let queryString = String(data: queryData, encoding: .utf8) {

                // URL encode the JSON string to safely pass it as a URL parameter
                if let encodedQuery = queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                   return encodedQuery
                }
            }
        return ""
    }
}
