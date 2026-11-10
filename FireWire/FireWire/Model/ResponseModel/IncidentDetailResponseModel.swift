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
    let subLocalityName: String?
    var commentCount, likeCount: Int
    let points: [Point]?
    var isLiked: Bool = false
    /// Server-resolved unit chip colors (12.1.2+). nil on older servers, in which
    /// case the hardcoded UnitCategory classifier is the fallback.
    let respondingUnitColors: [UnitColorModel]?
    let unitLegend: [UnitLegendModel]?
    let unitColorsConfigured: Bool?
    /// Title history, oldest first (`[{version, title, at}]`). Absent on API
    /// builds that predate the progression endpoint, so it decodes leniently.
    let progression: [ProgressionEntry]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case latitude, longitude, address, respondingUnits, featured, sendPushNotification, field1Value, field2Value, field3Value, field4Value, field5Value, createdAt, updatedAt, featuredImageUrl, subLocalityName
        case v = "__v"
        case commentCount, likeCount
        case points
        case isLiked
        case respondingUnitColors, unitLegend, unitColorsConfigured
        case progression
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
        subLocalityName = try container.decodeIfPresent(String.self, forKey: .subLocalityName)
        points = try container.decodeIfPresent([Point].self, forKey: .points)
        respondingUnitColors = try? container.decodeIfPresent([UnitColorModel].self, forKey: .respondingUnitColors)
        unitLegend = try? container.decodeIfPresent([UnitLegendModel].self, forKey: .unitLegend)
        unitColorsConfigured = try? container.decodeIfPresent(Bool.self, forKey: .unitColorsConfigured)
        progression = try? container.decodeIfPresent([ProgressionEntry].self, forKey: .progression)

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
    /// Straight-line distance from the incident, in miles. The server sorts
    /// `points` nearest first. nil on API builds that predate the field.
    let distanceMiles: Double?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case locality, latitude, longitude, address, name, notes, deleted, distanceMiles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        locality = try container.decodeIfPresent(String.self, forKey: .locality)
        latitude = try container.decodeIfPresent(String.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(String.self, forKey: .longitude)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        deleted = try container.decode(Bool.self, forKey: .deleted)
        // Additive field: a missing or oddly-typed value must never fail the
        // whole incident decode.
        if let miles = try? container.decodeIfPresent(Double.self, forKey: .distanceMiles) {
            distanceMiles = miles
        } else if let text = try? container.decodeIfPresent(String.self, forKey: .distanceMiles) {
            distanceMiles = Double(text)
        } else {
            distanceMiles = nil
        }
    }
}

/// One entry of the incident's title history ("10-75" → "ALL HANDS" → …).
struct ProgressionEntry: Codable {
    let version: Int?
    let title: String?
    /// ISO-8601 UTC timestamp of the title change.
    let at: String?

    enum CodingKeys: String, CodingKey {
        case version, title, at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try? container.decodeIfPresent(Int.self, forKey: .version)
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        at = try? container.decodeIfPresent(String.self, forKey: .at)
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

/// One resolved unit chip color from the server. Hex is #RRGGBB or #RRGGBBAA.
struct UnitColorModel: Codable {
    let unit: String?
    let bg: String?
    let fg: String?
    let bgDark: String?
    let fgDark: String?
    let category: String?
}

/// One legend entry (category label + swatch color) from the server.
struct UnitLegendModel: Codable {
    let key: String?
    let label: String?
    let color: String?
    let colorDark: String?
}
