//
//  NewsListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/12/24.
//

import Foundation

final class NewsListViewModel {
    var newsList: [NewsDataModel] = []
    var delegate: NewsListViewDelegate?

    func getNewsList() {
        let parameters: [String: Any] = ["sortBy": "createdAt", "sortDir": "desc", "offset": 1, "limit": 10]

        APIRequest().callGetApi(
            apiEndPoint: APIEndpoints.newsList,
            parameters: parameters,
            expect: NewsResponseModel.self)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if let newsListResponse = apiResponse as? NewsResponseModel {
                self?.newsList = newsListResponse.data
                self?.delegate?.dataReceived()
            } else {
                print("Invalid response object")
            }
        }
    }
}
