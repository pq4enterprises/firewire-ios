//
//  IncidentLocalityRequestModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import Foundation

struct IncidentLocalityRequestModel {
    public var sortBy: String
    public var sortDir: String
    public var offset: Int
    public var limit: Int
    public var listType: ListType?
}

struct ListType {
    public var type: String

    func toDictionary() -> [String: Any] {
        return ["type": type]
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

//    public var selectedAreas: [SelectedAreas]
//
//    init(sortBy: String, sortDir: String, offset: Int, limit: Int, selectedAreas: [SelectedAreas] = []) {
//        self.sortBy = sortBy
//        self.sortDir = sortDir
//        self.offset = offset
//        self.limit = limit
//        self.selectedAreas = selectedAreas
//    }

//struct SelectedAreas {
//    public var userId: String
//    public var localityId: String
//    public var sublocalityId: String
//
//    func toDictionary() -> [String: Any] {
//        return [
//            "userId": self.userId,
//            "localityId": self.localityId,
//            "sublocalityId": self.sublocalityId
//        ]
//    }
//}
