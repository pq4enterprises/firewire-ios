//
//  SelectedIncidentCommentsModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 03/10/25.
//

struct SelectedIncidentCommentsModel {
    public var incidentID: String
    public var commentParentID: String?
    public var mentionsUserID: String?
    public var mentionsUserName: String?

    public init(incidentID: String, commentParentID: String? = nil, mentionsUserID: String? = nil, mentionsUserName: String? = nil) {
        self.incidentID = incidentID
        self.commentParentID = commentParentID
        self.mentionsUserID = mentionsUserID
        self.mentionsUserName = mentionsUserName
    }
}
