//
//  IncidentListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 07/12/24.
//

import Foundation

final class IncidentListViewModel: PaginatableViewModel {
    typealias DataType = IncidentDataModel

    var currentPage: Int = 1
    var totalPages: Int = 1
    var limit: Int = 10
    var items: [IncidentDataModel] = []
    var selectedLocalities: SelectedLocalities?
    var delegate: PostListViewDelegate?

    init(_ incidentList: [IncidentDataModel] = [], _ selectedLocalities: SelectedLocalities? = nil) {
        self.selectedLocalities = selectedLocalities
        filterIncidentList(selectedLocalities: selectedLocalities)
    }

    func fetchData(forPage page: Int, completion: @escaping (Result<[IncidentDataModel], any Error>) -> Void) {
        var requestModel = IncidentRequestModel(sortBy: "createdAt", sortDir: "desc", offset: page, limit: limit)

        // Add filters if available
        if let selectedLocalities = selectedLocalities {
            requestModel.query = QueryModel(
                locality: selectedLocalities.selectedLocalityIDs,
                subLocality: selectedLocalities.selectedSubLocalityIDs
            )
        }

        let getIncidentRequestModel = APIPayload.incidentList(requestModel).toDictionary()

        // Perform API call
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.incidentList,
            payload: getIncidentRequestModel,
            expect: IncidentResponseModel.self,
            requestType: APIConstants.GET
        ) { [weak self] response, _, _ in
            guard let apiResponse = response else {
                self?.delegate?.noIncidentData()
                return
            }

            if let incidentListResponse = apiResponse as? IncidentResponseModel {
                let newItems = incidentListResponse.data.data
                self?.totalPages = incidentListResponse.data.pageInfo.totalCount
                completion(.success(newItems))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
            }
        }
    }

    func didFetchData(_ data: [IncidentDataModel]) {
        items.append(contentsOf: data) // Append new items to existing list
        delegate?.filterDataReceived()
    }

    // Public method to trigger data fetching
    func filterIncidentList(selectedLocalities: SelectedLocalities?) {
        fetchData(forPage: currentPage) { [weak self] result in
            switch result {
            case .success(let newItems):
                self?.didFetchData(newItems)
            case .failure(let error):
                print("Error fetching incidents: \(error)")
            }
        }
    }
}
