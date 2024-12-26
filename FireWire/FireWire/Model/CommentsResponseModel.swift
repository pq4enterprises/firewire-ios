//
//  CommentsResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 26/12/24.
//

import Foundation

struct CommentsResponseModel: Codable {
    let message, code: String
    let data: [CommentsDataModel]
}

struct CommentsDataModel: Codable {
    let id: String
    let userID: UserIDModel
    //let img: [String?]
    //let comment: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userID = "userId"
        //case img, comment
    }
}

struct UserIDModel: Codable {
    let id: String
    let firstName: String
    //let locality, subLocality: [Locality?]
    //let lastName: String?
    //let img: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
    }
}
