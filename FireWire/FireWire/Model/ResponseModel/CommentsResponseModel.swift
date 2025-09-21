//
//  CommentsResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/12/24.
//

import Foundation

struct CommentsResponseModel: Codable {
    let message: String
    let code: String
    let data: CommentsDataModel
}

struct CommentsDataModel: Codable {
    let data: [CommentsData]
    let pageInfo: PageInfo
}

struct CommentsData: Codable, Hashable {
    let id: String
    let incidentId: String
    let userID: UserIdModel?
    let parentId: String?
    let img: [String]?
    let comment: String
    let featuredImage: Bool
    let createdAt: String
    var replies: [CommentsData]?
    var depth: Int = 0

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case incidentId
        case userID = "userId"
        case parentId
        case img
        case comment
        case featuredImage
        case createdAt
        case replies

    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func ==(lhs: CommentsData, rhs: CommentsData) -> Bool {
        lhs.id == rhs.id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        incidentId = try container.decode(String.self, forKey: .incidentId)
        userID = try container.decode(UserIdModel.self, forKey: .userID)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        img = try container.decodeIfPresent([String].self, forKey: .img)
        comment = try container.decode(String.self, forKey: .comment)
        featuredImage = try container.decodeIfPresent(Bool.self, forKey: .featuredImage) ?? false
        createdAt = try container.decode(String.self, forKey: .createdAt)
        replies = try container.decodeIfPresent([CommentsData].self, forKey: .replies)
    }

}

struct UserIdModel: Codable {
    let id: String
    let firstName: String
    let locality, subLocality: [Locality?]
    let lastName: String?
    let img: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName, lastName, locality, subLocality
        case img
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        locality = try container.decodeIfPresent([Locality].self, forKey: .locality) ?? []
        subLocality = try container.decodeIfPresent([Locality].self, forKey: .subLocality) ?? []
        lastName = try container.decode(String.self, forKey: .lastName)
        img = try container.decodeIfPresent(String.self, forKey: .img)
    }

}
