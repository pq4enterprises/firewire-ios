//
//  IncidentListRequestModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import Foundation

struct IncidentRequestModel {
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

    func toJsonString() -> String? {
        let dict = self.toDictionary()
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .fragmentsAllowed),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
}
