//
//  IncidentListRequestModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import Foundation

struct IncidentListRequestModel {
    public var sortBy: String
    public var sortDir: String
    public var offset: Int
    public var limit: Int
    public var query: QueryModel?
}

struct QueryModel {
    public var locality: [String]
    public var subLocality: [String]

    func toDictionary() -> [String: Any] {
        return [
            "locality": locality,
            "subLocality": subLocality
        ]
    }
}
