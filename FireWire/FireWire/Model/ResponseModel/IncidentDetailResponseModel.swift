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
    let respondingUnits: [String?]?
    let featured: Bool
    //let postFacebook: [PostFacebook]?
    //let postTwitter: [PostTwitter]?
    let sendPushNotification: Bool?
    let field1Value: String?
    let field2Value: String?
    let field3Value: String?
    let field4Value: String?
    let field5Value: String?
    let createdAt, updatedAt: String
    let v: Int
    let featuredImageUrl: String?
    var commentCount, likeCount: Int
    let points: [Point]?
    var isLiked: Bool = false

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case latitude, longitude, address, respondingUnits, featured, sendPushNotification, field1Value, field2Value, field3Value, field4Value, field5Value, createdAt, updatedAt, featuredImageUrl
        case v = "__v"
        case commentCount, likeCount
        case points
        case isLiked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        latitude = try container.decode(String.self, forKey: .latitude)
        longitude = try container.decode(String.self, forKey: .longitude)
        address = try container.decode(String.self, forKey: .address)
        featured = try container.decode(Bool.self, forKey: .featured)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        v = try container.decode(Int.self, forKey: .v)
        commentCount = try container.decode(Int.self, forKey: .commentCount)
        likeCount = try container.decode(Int.self, forKey: .likeCount)

        // Use decodeIfPresent for optional properties (will return nil if key is missing)
        sendPushNotification = try container.decodeIfPresent(Bool.self, forKey: .sendPushNotification)
        respondingUnits = try container.decodeIfPresent([String?].self, forKey: .respondingUnits)
        field1Value = try container.decodeIfPresent(String.self, forKey: .field1Value)
        field2Value = try container.decodeIfPresent(String.self, forKey: .field2Value)
        field3Value = try container.decodeIfPresent(String.self, forKey: .field3Value)
        field4Value = try container.decodeIfPresent(String.self, forKey: .field4Value)
        field5Value = try container.decodeIfPresent(String.self, forKey: .field5Value)
        featuredImageUrl = try container.decodeIfPresent(String.self, forKey: .featuredImageUrl)
        points = try container.decodeIfPresent([Point].self, forKey: .points)

        // Handle the isLiked flag with a default value if not present
        isLiked = (try? container.decode(Bool.self, forKey: .isLiked)) ?? false
    }
}

struct Point: Codable {
    let id: String
    let locality: String?
    let latitude: String?
    let longitude: String?
    let address: String?
    let name: String?
    let notes: String?
    let deleted: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case locality, latitude, longitude, address, name, notes, deleted
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

