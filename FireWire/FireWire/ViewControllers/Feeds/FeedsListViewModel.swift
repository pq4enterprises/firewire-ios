//
//  FeedsListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 23/01/25.
//

import Foundation

final class FeedsListViewModel: PaginatableViewModel {
    typealias DataType = FeedGroupedData

    var currentPage: Int = 1
    var totalPages: Int = 1
    var limit: Int = 10
    var items: [FeedGroupedData] = []
    var delegate: FeedListViewDelegate?

    func fetchData(forPage page: Int, completion: @escaping (Result<[FeedGroupedData], any Error>) -> Void) {
        let requestModel = CommonRequestModel(sortBy: "createdAt", sortDir: "desc", offset: page, limit: limit)
        let getFeedRequestModel = APIPayload.feedList(requestModel).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.feedList,
            payload: getFeedRequestModel,
            expect: FeedListResponseModel.self,
            requestType: APIConstants.GET)
        { [weak self] response, _, _ in

            guard let feedListResponse = response as? FeedListResponseModel else {
                let errorMessage = (response == nil) ? "Invalid request" : "Unexpected response format"
                self?.delegate?.errorReceived(message: errorMessage)
                return
            }

            if let feedList = feedListResponse.data {
                self?.totalPages = feedListResponse.pageInfo.totalCount
                DispatchQueue.main.async {
                    let newList = self?.groupFeedDataByLocality(feedListDataArray: feedList)
                    completion(.success(newList ?? []))
                }
            }else {
                self?.delegate?.errorReceived(message: "Invalid response")
            }
        }
    }

    func didFetchData(_ data: [FeedGroupedData]) {
        items.append(contentsOf: data) // Append new items to existing list
        delegate?.dataReceived()
    }

    func getFeedList() {
        fetchData(forPage: currentPage) { [weak self] result in
            switch result {
            case .success(let newItems):
                self?.didFetchData(newItems)
            case .failure(let error):
                print("Error fetching incidents: \(error)")
            }
        }
    }

    func groupFeedDataByLocality(feedListDataArray: [FeedListData]) -> [FeedGroupedData] {
        var groupedData = [FeedGroupedData]()

        // Grouping the feed list data by locality name
        let grouped = Dictionary(grouping: feedListDataArray) { $0.locality.name }

        for (localityName, feeds) in grouped {
            // Create the FeedGroupedData for each locality
            let feedGrouped = FeedGroupedData(localityName: localityName, feedList: feeds)

            // Add the grouped data into the result array
            groupedData.append(feedGrouped)
        }

        return groupedData
    }
}
