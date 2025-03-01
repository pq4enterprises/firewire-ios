//
//  FeedListResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 23/01/25.
//

struct FeedListResponseModel: Codable {
    let data: [FeedListData]?
    let pageInfo: PageInfo
}

// MARK: - Datum
struct FeedListData: Codable {
    let id: String
    let locality: Locality
    let name: String
    let url: String
    let createdAt: String
    var isPlaying: Bool = false

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case locality, name, url, createdAt
    }
}

struct FeedGroupedData {
    let localityName: String
    var feedList: [FeedListData]
}
