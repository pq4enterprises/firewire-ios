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

struct CommentsData: Codable {
    let id: String
    let userID: UserIdModel
    let img: [String]
    let comment: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userID = "userId"
        case img, comment
    }
}

struct UserIdModel: Codable {
    let id: String
    let firstName: String
    let locality, subLocality: [Locality?]
    let lastName: String?
    //let img: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName, lastName, locality, subLocality
    }
}
