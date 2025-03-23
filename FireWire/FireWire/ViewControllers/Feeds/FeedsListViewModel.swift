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
                    let newList = self?.groupFeedDataByLocality(feedListDataArray: feedList, existingGroupedData: self?.items ?? [])
                    completion(.success(newList ?? []))
                }
            } else {
                self?.delegate?.errorReceived(message: "Invalid response")
            }
        }
    }

    func didFetchData(_ data: [FeedGroupedData]) {
        items.removeAll()
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

    func groupFeedDataByLocality(feedListDataArray: [FeedListData], existingGroupedData: [FeedGroupedData]) -> [FeedGroupedData] {
        // Convert existing grouped data into a dictionary for quick lookups
        var groupedDict = Dictionary(uniqueKeysWithValues: existingGroupedData.map { ($0.localityName, $0) })

        // New feed data grouped by locality name
        let newGrouped = Dictionary(grouping: feedListDataArray) { $0.locality.name }

        // Merge new data with existing groups while avoiding duplicates
        for (localityName, newFeeds) in newGrouped {
            if var existingGroup = groupedDict[localityName] {
                let existingFeedIds = Set(existingGroup.feedList.map { $0.id }) // Assuming FeedListData has a unique 'id'
                let uniqueFeeds = newFeeds.filter { !existingFeedIds.contains($0.id) } // Filter duplicates

                if !uniqueFeeds.isEmpty {
                    existingGroup.feedList.append(contentsOf: uniqueFeeds)
                    groupedDict[localityName] = existingGroup
                }
            } else {
                groupedDict[localityName] = FeedGroupedData(localityName: localityName, feedList: newFeeds)
            }
        }

        // Return sorted grouped data
        return groupedDict.values.sorted { $0.localityName > $1.localityName }
    }
}
