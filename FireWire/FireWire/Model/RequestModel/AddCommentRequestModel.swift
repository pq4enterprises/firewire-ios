//
//  AddCommentRequestModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 11/01/25.
//

import Foundation

struct AddCommentRequestModel {
    public var userId: String
    public var incidentId: String
    public var parentId: String?
    public var mentions: [String] = []
    public var type: String
    public var comment: String
    public var img: String
}
