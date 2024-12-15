//
//  NewsResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/12/24.
//

import Foundation

struct NewsResponseModel: Codable {
    let data: [NewsDataModel]
    let pageInfo: PageInfo
}

// MARK: - Datum
struct NewsDataModel: Codable {
    let id, title: String
    let link: String
    let url: String?
    let type: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, link, url, type, createdAt
    }
}
