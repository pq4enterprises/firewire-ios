//
//  CommentsListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/12/24.
//

import Foundation
import UIKit

public final class CommentsListViewModel: PaginatableViewModel {
    typealias DataType = CommentsData

    var currentPage: Int = 1
    var totalPages: Int = 1
    var limit: Int = 10
    var items: [CommentsData] = []
    var delegate: CommentsListViewDelegate?
    var selectedIncidentID: String?

    func fetchData(forPage page: Int, completion: @escaping (Result<[CommentsData], any Error>) -> Void) {
        guard let selectedIncidentID else { return }
        let requestURL = String(format: APIEndpoints.commentsList, selectedIncidentID)

        let requestModel = CommonRequestModel(sortBy: "createdAt", sortDir: "desc", offset: page, limit: limit)
        let getCommentsRequestModel = APIPayload.commentsList(requestModel).toDictionary()

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
                let newItems = commentsResponse.data.data
                self?.totalPages = commentsResponse.data.pageInfo.totalCount
                DispatchQueue.main.async {
                    if newItems.count > 0 {
                        completion(.success(newItems))
                    } else {
                        if self?.items.isEmpty == true && newItems.isEmpty {
                            self?.delegate?.noCommentsForIncident()
                        }
                    }
                }
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
            }
        }
    }

    func didFetchData(_ data: [CommentsData]) {
        if !data.isEmpty{
            items.append(contentsOf: data) // Append new items to existing list

            if items.isEmpty {
                delegate?.noCommentsForIncident()
                return
            }

            delegate?.dataReceived()
        }
    }

    func getCommentsList(for incidentID: String) {
        selectedIncidentID = incidentID
        fetchData(forPage: currentPage) { [weak self] result in
            switch result {
            case .success(let newItems):
                self?.didFetchData(newItems)
            case .failure(_):
                self?.delegate?.noCommentsForIncident()
            }
        }
    }

    func addComment(_ model: AddCommentRequestModel) {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.addComment,
            payload: APIPayload.addComment(model).toDictionary(),
            expect: SuccessResponseModel.self)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if apiResponse is SuccessResponseModel {
                if let incidentId = self?.selectedIncidentID {
                    // Reset the items list and append new items
                    self?.delegate?.commentAdded()
                    self?.currentPage = 1
                    self?.items.removeAll()
                    self?.getCommentsList(for: incidentId)
                }
            } else {
                print("Invalid response object")
            }
        }
    }

    func requestImageUpload(_ image: UIImage, onImageUploaded: @escaping (String) -> Void) {
        APIRequest().uploadImage(
            apiEndPoint: APIEndpoints.uploadImage,
            image: image,
            expect: UploadImageResponseModel.self)
        { [weak self] response, _, _ in
            guard let apiResponse = response as? UploadImageResponseModel else {
                let errorMessage = (response == nil) ? "Invalid request" : "Unexpected response format"
                self?.delegate?.error(message: errorMessage)
                return
            }

            if apiResponse.code.lowercased() == "success" {
                DispatchQueue.main.async {
                    if let imageUrl = apiResponse.data?.url {
                        onImageUploaded(imageUrl[0])
                    } else {
                        self?.delegate?.error(message: "Image upload failed")
                    }
                }
            } else {
                self?.delegate?.error(message: apiResponse.message)
            }
        }
    }
}
