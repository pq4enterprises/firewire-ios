//
//  IncidentListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 17/07/25.
//

protocol APIDelegate: AnyObject {
    func error(message: String)
}

final class IncidentListViewModel {
    var delegate: APIDelegate?

    func favouriteIncident(incidentId: String, like: Bool, completion: @escaping (Bool) -> Void) {
        let requestModel = APIPayload.favouriteIncident(
            userId: FWUserDefaults().userID ?? "",
            incidentId: incidentId,
            type: like == true ? "unlike" : "like"
        ).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.favIncident,
            payload: requestModel as JSON,
            expect: SuccessResponseModel.self
        ) { response, _, error in
            if let errorMessage = error {
                self.delegate?.error(message: errorMessage)
                return
            }
            guard let apiResponse = response as? SuccessResponseModel else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self.delegate?.error(message: errorMessage)
                return
            }

            if apiResponse.code == "unlike_success" || apiResponse.code == "like_success" {
                completion(true)
            } else {
                self.delegate?.error(message: apiResponse.message)
            }
        }
    }
}
