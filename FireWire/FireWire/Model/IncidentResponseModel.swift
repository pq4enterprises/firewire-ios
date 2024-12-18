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
    let latitude, longitude, address, field1Value, createdAt: String
    let featuredImageURL: String
    let commentCount, likeCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case locality = "localityDetails"
        case subLocality = "subLocalityDetails"
        case latitude, longitude, address, field1Value, createdAt
        case featuredImageURL = "featuredImageUrl"
        case commentCount, likeCount
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
