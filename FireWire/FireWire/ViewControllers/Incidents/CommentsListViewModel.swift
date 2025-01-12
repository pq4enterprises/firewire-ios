//
//  CommentsListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/12/24.
//

import Foundation

public final class CommentsListViewModel {
    var commentsList: [CommentsData] = []
    var delegate: CommentsListViewDelegate?

    func getCommentsList(for incidentID: String) {
        let requestURL = String.init(format: APIEndpoints.commentsList, incidentID)

        let requestModel = IncidentLocalityRequestModel(sortBy: "createdAt", sortDir: "desc", offset: 1, limit: 10)
        let getCommentsRequestModel = APIPayload.incidentLocalityList(requestModel).toDictionary()


        APIRequest().callApi(
            apiEndPoint: requestURL,
            payload: getCommentsRequestModel,
            expect: CommentsResponseModel.self,
            requestType: APIConstants.GET)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                self?.delegate?.noCommentsForIncident()
                return
            }

            if let commentsResponse = apiResponse as? CommentsResponseModel {
                self?.commentsList = commentsResponse.data.data
                DispatchQueue.main.async {
                    self?.delegate?.dataReceived()
                }
            }else{
                print("Invalid response object")
            }
        }
    }

    func addComment(_ model: AddCommentRequestModel){
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.addComment,
            payload: APIPayload.addComment(model).toDictionary(),
            expect: SuccessResponseModel.self)
        {[weak self] response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if apiResponse is SuccessResponseModel {
                DispatchQueue.main.async {
                    self?.delegate?.commentAdded()
                }
            }else{
                print("Invalid response object")
            }
        }
    }
}
