//
//  LocalityResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 18/12/24.
//

import Foundation

struct LocalityResponseModel: Codable {
    let message, code: String
    let data: LocalityResponseDataModel?
}

struct LocalityResponseDataModel: Codable {
    let data: [LocalityResponseData]
    let pageInfo: PageInfo
}

struct LocalityResponseData: Codable {
    let id: String
    let name: String
    let state: String
    var subLocality: [SubLocality]
    var unit: [UnitDataModel?]?
    var incidentType: [IncidentTypeModel?]?

    var isAllItemChecked: Bool = false

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, state, subLocality, unit
        case incidentType
    }
}

struct SubLocality: Codable {
    let id, name, latitude, longitude: String
    var isChecked: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, latitude, longitude
        case isChecked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decodeIfPresent(String.self, forKey: .latitude) ?? ""
        longitude = try container.decodeIfPresent(String.self, forKey: .longitude) ?? ""
        isChecked = (try? container.decode(Bool.self, forKey: .isChecked)) ?? false
    }
}

struct UnitDataModel: Codable {
    let id: String
    let unitName: String?
    var isChecked: Bool = false

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case unitName
        case isChecked
    }

    // Custom initializer to handle the case when `isChecked` is missing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        unitName = try container.decodeIfPresent(String.self, forKey: .unitName)
        // Provide default value false if isChecked is missing
        isChecked = (try? container.decode(Bool.self, forKey: .isChecked)) ?? false
    }
}

struct IncidentTypeModel: Codable {
    let id: String
    let optionName: String?
    var isChecked: Bool = false

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case optionName
        case isChecked
    }

    // Custom initializer to handle the case when `isChecked` is missing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        optionName = try container.decodeIfPresent(String.self, forKey: .optionName)
        // Provide default value false if isChecked is missing
        isChecked = (try? container.decode(Bool.self, forKey: .isChecked)) ?? false
    }
}
