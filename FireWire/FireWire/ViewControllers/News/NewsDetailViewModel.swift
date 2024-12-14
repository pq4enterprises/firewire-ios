//
//  NewsDetailViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/12/24.
//

import Foundation

final class NewsDetailViewModel {

    var newsDetail: NewsDetailResponseModel?
    var delegate: NewsDetailViewDelegate?

    init(newsID: String) {
        getNewsDetail(for: newsID)
    }

    func getNewsDetail(for newsID: String) {
        let requestURL = String.init(format: APIEndpoints.newsDetail, newsID)

        APIRequest().callGetApi(
            apiEndPoint: requestURL,
            parameters: nil,
            expect: NewsDetailResponseModel.self)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if let newsDetailResponse = apiResponse as? NewsDetailResponseModel {
                self?.newsDetail = newsDetailResponse
                self?.delegate?.dataReceived()
            }else{
                print("Invalid response object")
            }
        }
    }
}
