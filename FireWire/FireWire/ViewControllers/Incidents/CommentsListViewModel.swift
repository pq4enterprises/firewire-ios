//
//  CommentsListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/12/24.
//

import Foundation

public final class CommentsListViewModel {

    var commentsList: [CommentsDataModel] = []
    var delegate: CommentsListViewDelegate?

    func getCommentsList(for incidentID: String) {
        let requestURL = String.init(format: APIEndpoints.commentsList, incidentID)

        APIRequest().callGetApi(
            apiEndPoint: requestURL,
            parameters: nil,
            expect: CommentsResponseModel.self)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                self?.delegate?.noCommentsForIncident()
                return
            }

            if let commentsResponse = apiResponse as? CommentsResponseModel {
                self?.commentsList = commentsResponse.data.compactMap { $0 }
                DispatchQueue.main.async {
                    self?.delegate?.dataReceived()
                }
            }else{
                print("Invalid response object")
            }
        }
    }
}
