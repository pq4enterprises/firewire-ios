//
//  IncidentResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 07/12/24.
//

import Foundation

// MARK: - IncidentResponseModel
struct IncidentResponseModel: Codable {
    let message: String
    let code: String
    let data: IncidentDataResponseModel
}

struct IncidentDataResponseModel: Codable {
    let data: [IncidentDataModel]
    let pageInfo: PageInfo
}

// MARK: - Datum
struct IncidentDataModel: Codable {
    let id: String
    let locality, subLocality: [Locality]
    let latitude, longitude, address, createdAt: String
    let field1Value, field2Value, field3Value: String
    let featuredImageURL: String?
    let commentCount, likeCount: Int
    var isLiked: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case locality = "localityDetails"
        case subLocality = "subLocalityDetails"
        case latitude, longitude, address, createdAt
        case field1Value, field2Value, field3Value
        case featuredImageURL = "featuredImageUrl"
        case commentCount, likeCount, isLiked
    }
}

// MARK: - Locality
struct Locality: Codable {
    let name: String
}

// MARK: - PageInfo
struct PageInfo: Codable {
    let offset, limit, totalCount: Int
}
