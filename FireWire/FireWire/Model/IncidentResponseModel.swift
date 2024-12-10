//
//  IncidentResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 07/12/24.
//

import Foundation

// MARK: - IncidentResponseModel
struct IncidentResponseModel: Codable {
    let data: [IncidentDataModel]
    let pageInfo: PageInfo
}

// MARK: - Datum
struct IncidentDataModel: Codable {
    let id: String
    let locality, subLocality: Locality
    let latitude, address, field1Value, createdAt: String
    let description, box: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case locality, subLocality, latitude, address, field1Value, createdAt, description, box
    }
}

// MARK: - Locality
struct Locality: Codable {
    let id, name: String
    let state: String?
    let latitude, longitude: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, state, latitude, longitude
    }
}

// MARK: - PageInfo
struct PageInfo: Codable {
    let offset, limit, totalCount: Int
}
