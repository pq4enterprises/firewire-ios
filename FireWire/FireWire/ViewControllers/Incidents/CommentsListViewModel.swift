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

        APIRequest().callApi(
            apiEndPoint: requestURL,
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
}
