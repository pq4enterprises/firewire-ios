//
//  SelectAreaViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 18/12/24.
//

import Foundation

final class SelectAreaViewModel {
    var localityData: [LocalityResponseData] = []
    var delegate: SelectAreaViewDelegate?

    func getLocalities() {
        let parameters: [String: Any] = ["sortBy": "createdAt", "sortDir": "desc", "offset": 1, "limit": 10]

        APIRequest().callGetApi(
            apiEndPoint: APIEndpoints.localityList,
            parameters: parameters,
            expect: LocalityResponseModel.self)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if let localityResponse = apiResponse as? LocalityResponseModel {
                self?.localityData = localityResponse.data.data
                self?.delegate?.dataReceived()
            }else{
                print("Invalid response object")
            }
        }
    }
}
