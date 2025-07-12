//
//  SelectedNotificationModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 12/02/25.
//

struct SelectedNotificationModel {
    public let userId: String
    public let notificationId: String
    public let type: String
    public let forLocalityId: String

    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "notificationId": notificationId,
            "type": type
        ]
    }
}
