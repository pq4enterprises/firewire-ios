//
//  IncidentDetailResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 10/12/24.
//

import Foundation

struct IncidentDetailResponseModel: Codable {
    let message, code: String
    let data: [IncidentDetailModel]
}

struct IncidentDetailModel: Codable {
    let id: String
    //let locality, subLocality: Locality
    let latitude, longitude, address: String
    let respondingUnits: [String]?
    let featured, sendPushNotification: Bool
    //let postFacebook: [PostFacebook]?
    //let postTwitter: [PostTwitter]?
    let field1Value: String?
    let field2Value: String?
    let field3Value: String?
    let field4Value: String?
    let field5Value: String?
    let createdAt, updatedAt: String
    let v: Int
    let featuredImageUrl: String?
    let commentCount, likeCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case latitude, longitude, address, respondingUnits, featured, sendPushNotification, field1Value, field2Value, field3Value, field4Value, field5Value, createdAt, updatedAt, featuredImageUrl
        case v = "__v"
        case commentCount, likeCount
    }
}

struct PostFacebook: Codable {
    let pageID, pageName, accessToken, id: String?
    let checked: Bool?

    enum CodingKeys: String, CodingKey {
        case pageID = "pageId"
        case pageName, accessToken
        case id = "_id"
        case checked
    }
}

struct PostTwitter: Codable {
    let twitterPage: String?
    let checked: Bool?
}

