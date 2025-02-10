//
//  SelectedAreaModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 10/02/25.
//

struct SelectedAreaModel {
    public let userId: String
    public let localityId: String
    public let subLocalityId: String

    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "localityId": localityId,
            "sublocalityId": subLocalityId
        ]
    }
}
