//
//  NewsListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/12/24.
//

import Foundation

final class NewsListViewModel {
    var newsList: [NewsItem] = []
    var delegate: NewsListViewDelegate?

    func getNewsList(){
        APIRequest().fetchRSS(
            apiEndPoint: APIEndpoints.newsList,
            modelType: NewsResponseModel.self) { [weak self] response, _, _ in

                guard let apiResponse = response else {
                    return
                }

                if let newsListResponse = apiResponse as? NewsResponseModel {
                    self?.newsList = newsListResponse.channel.item
                    self?.delegate?.dataReceived()
                }
            }
    }
}
