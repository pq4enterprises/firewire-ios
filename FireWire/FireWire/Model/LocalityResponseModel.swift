//
//  LocalityResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 18/12/24.
//

import Foundation

struct LocalityResponseModel: Codable {
    let message, code: String
    let data: LocalityResponseDataModel
}

struct LocalityResponseDataModel: Codable {
    let data: [LocalityResponseData]
    let pageInfo: PageInfo
}

struct LocalityResponseData: Codable {
    let id: String
    let name: String
    let state: String
    let subLocality: [SubLocality]

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, state, subLocality
    }
}

struct SubLocality: Codable {
    let id, name, latitude, longitude: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, latitude, longitude
    }
}
